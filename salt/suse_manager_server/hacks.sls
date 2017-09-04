include:
  - suse_manager_server.benchmark

# HACK: increase memory, thread, connection limits across the board

tomcat_increase_memory:
  file.replace:
    - name: /etc/tomcat/tomcat.conf
    - pattern: Xmx1G
    - repl: Xmx8G
    - require:
      - sls: suse_manager_server.benchmark

rhn_increase_limits:
  file.append:
    - name: /etc/rhn/rhn.conf
    - text: |
        # increase Taskomatic workers
        org.quartz.threadPool.threadCount = 100
        # have Taskomatic check more frequently for new jobs to pick up
        org.quartz.scheduler.idleWaitTime = 1000
        # fire multiple Taskomatic tasks in one shot (quartz 2 and later)
        org.quartz.scheduler.batchTriggerAcquisitionMaxCount = 50
        # increase Tomcat's Salt workers
        java.message_queue_thread_pool_size = 100
        # increase the number of Postgres connections, so that workers will not be blocked
        hibernate.c3p0.max_size = 150
        # allow more time for minions to respond. AWS t2.nanos can get slow
        salt_presence_ping_timeout = 20
        salt_presence_ping_gather_job_timeout = 5
    - require:
      - sls: suse_manager_server.benchmark

salt_master_increase_threads:
  file.replace:
    - name: /etc/salt/master.d/susemanager.conf
    - pattern: 'worker_threads: [0-9]+'
    - repl: 'worker_threads: 100'
    - require:
      - sls: suse_manager_server.benchmark

apache_increase_page_time_limit:
  file.replace:
    - name: /etc/apache2/conf.d/zz-spacewalk-www.conf
    - pattern: 'ProxyTimeout [0-9]+'
    - repl: 'ProxyTimeout 36000'
    - require:
      - sls: suse_manager_server.benchmark

# HACK: disable job cache automatic cleanup

salt_master_disable_job_cache_cleanup:
  file.managed:
    - name: /etc/salt/master.d/keep_jobs.conf
    - contents: |
        keep_jobs: 0
    - require:
      - sls: suse_manager_server.benchmark

# HACK: avoid the Taskomatic action cleanup task to interfere with long-running Tomcat return result processing

change_minion_action_cleanup_schedule:
  cmd.run:
    - name: spacewalk-sql - <<<"UPDATE rhnTaskoSchedule SET cron_expr = '0 0 0 * * ?' WHERE job_label = 'minion-action-cleanup-default';"
    - require:
      - sls: suse_manager_server.benchmark

# Restart all services affected by hacks above

tomcat_restart:
  service.running:
    - name: tomcat
    - listen:
      - file: /etc/tomcat/tomcat.conf
      - file: /etc/rhn/rhn.conf

taskomatic_restart:
  service.running:
    - name: taskomatic
    - listen:
      - file: /etc/rhn/rhn.conf

salt_master_restart:
  service.running:
    - name: salt-master
    - listen:
      - file: /etc/salt/master.d/susemanager.conf
      - file: /etc/salt/master.d/keep_jobs.conf

# HACK: make use of AWS's internal disks
# set up a RAID 1 on those ephemeral SSDs and move all important directories there
# then, bind-mount them and hope for the best

raid:
  pkg.installed:
    - name: mdadm
  cmd.run:
    - name: yes|mdadm --create /dev/md0 --level=stripe --raid-devices=2 /dev/xvdb /dev/xvdc
    - creates: /dev/md0
    - require:
      - pkg: mdadm

data_partition:
  pkg.installed:
    - name: xfsprogs
  cmd.run:
    - name: /usr/sbin/parted -s /dev/md0 mklabel gpt && /usr/sbin/parted -s /dev/md0 mkpart primary 2048 100% && sleep 5 && mkfs.xfs /dev/md0p1
    - creates: /dev/md0p1
    - require:
      - pkg: xfsprogs
      - cmd: raid

important_directories_in_raid:
  cmd.run:
    - name: |
        spacewalk-service stop &&
        systemctl stop postgresql &&
        mkdir -p /mnt/raid &&
        mount -t xfs /dev/md0p1 /mnt/raid &&
        cp -rp /bin /mnt/raid && mount --bind /mnt/raid/bin /bin &&
        cp -rp /etc /mnt/raid && mount --bind /mnt/raid/etc /etc &&
        cp -rp /home /mnt/raid && mount --bind /mnt/raid/home /home &&
        cp -rp /lib /mnt/raid && mount --bind /mnt/raid/lib /lib &&
        cp -rp /lib64 /mnt/raid && mount --bind /mnt/raid/lib64 /lib64 &&
        cp -rp /sbin /mnt/raid && mount --bind /mnt/raid/sbin /sbin &&
        cp -rp /srv /mnt/raid && mount --bind /mnt/raid/srv /srv &&
        cp -rp /tmp /mnt/raid && mount --bind /mnt/raid/tmp /tmp &&
        cp -rp /usr /mnt/raid && mount --bind /mnt/raid/usr /usr &&
        cp -rp /var /mnt/raid && mount --bind /mnt/raid/var /var &&
        systemctl daemon-reload &&
        systemctl start postgresql &&
        spacewalk-service start
    - creates: /mnt/raid/bin
    - require:
      - cmd: data_partition
      - service: tomcat_restart
      - service: taskomatic_restart
      - service: salt_master_restart
