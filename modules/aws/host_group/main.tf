terraform {
    required_version = ">= 0.10.7"
}

resource "aws_launch_configuration" "launch_configuration" {
  count = "${var.count * length(var.amis)}"
  name_prefix = "${var.name_prefix}-host-group-"
  image_id = "${element(var.amis, count.index)}"
  instance_type = "${var.instance_type}"

  key_name = "${var.key_name}"
  security_groups = ["${var.private_security_group_id}"]
  enable_monitoring = "${var.monitoring}"
  user_data = <<EOF
#!/bin/bash
cat >/etc/salt/grains <<EOFF
hostname: $(cat /etc/hostname)
domain: ${var.region == "us-east-1" ? "ec2.internal" : "${var.region}.compute.internal"}
use_avahi: False
mirror: ${var.mirror_private_name}
version: ${var.version}
database: ${var.database}
channels: [${join(",", var.channels)}]
role: ${var.role}
cc_username: ${var.cc_username}
cc_password: ${var.cc_password}
server: ${element(var.servers, count.index / length(var.amis))}
iss_master: ${var.iss_master}
iss_slave: ${var.iss_slave}
for_development_only: True
for_testsuite_only: False
unsafe_postgres: ${var.unsafe_postgres}
auto_accept: ${var.auto_accept}
monitored: ${var.monitored}
timezone: ${var.timezone}
authorized_keys: null
additional_repos: {${join(", ", formatlist("'%s': '%s'", keys(var.additional_repos), values(var.additional_repos)))}}
additional_packages: [${join(", ", formatlist("'%s'", var.additional_packages))}]
gpg_keys:  [${join(", ", formatlist("'%s'", var.gpg_keys))}]
reset_ids: true

susemanager:
  activation_key: ${var.activation_key}
EOFF
salt-call --local --file-root=/root/salt/ --output=quiet state.sls default
salt-call --local --file-root=/root/salt/ --log-level=info state.highstate
EOF

  root_block_device {
    volume_size = "${var.volume_size}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "autoscaling_group" {
  count = "${var.count * length(var.amis)}"
  availability_zones = ["${var.availability_zone}"]
  name = "${var.name_prefix}-autoscaling-group-${var.name}-${count.index}"
  desired_capacity = "${var.host_count / length(var.amis)}"
  max_size = "${var.host_count / length(var.amis)}"
  min_size = "${var.host_count / length(var.amis)}"
  health_check_type = "EC2"
  launch_configuration = "${element(aws_launch_configuration.launch_configuration.*.name, count.index)}"
  vpc_zone_identifier = ["${var.private_subnet_id}"]
  wait_for_capacity_timeout = "0"
  default_cooldown = 0

  lifecycle {
    create_before_destroy = true
  }
}
