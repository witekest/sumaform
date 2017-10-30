include:
  - default

tools_repo:
  file.managed:
    - name: /etc/zypp/repos.d/home_SilvioMoioli_tools.repo
    - source: salt://mirror/repos.d/home_SilvioMoioli_tools.repo
    - template: jinja
    - require:
      - sls: default

refresh_tools_repo:
  cmd.run:
    - name: zypper --non-interactive --gpg-auto-import-keys refresh
    - require:
      - file: tools_repo

terraform:
  pkg.latest:
    - pkgs:
      - terraform
      - terraform-provider-libvirt
    - require:
      - cmd: refresh_tools_repo

sumaform:
  git.latest:
    - name: https://github.com/moio/sumaform.git
    - target: /root/sumaform

# allow SSH self-connections to use localhost as a bastion host
ssh_key:
  cmd.run:
    - name: ssh-keygen -q -N '' -f /root/.ssh/id_rsa
    - creates: /root/.ssh/id_rsa.pub

self_key_authorization:
  cmd.run:
    - name: cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
    - unless: grep `awk '{print $2}' < ~/.ssh/id_rsa.pub` <~/.ssh/authorized_keys
    - require:
      - cmd: ssh_key
