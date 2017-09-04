module "aws_proxy" {
  source = "../host"
  name = "${var.proxy_name}"
  region = "${var.region}"
  availability_zone = "${var.availability_zone}"
  count = "${var.count}"
  ami = "${var.proxy_ami}"
  instance_type = "${var.proxy_instance_type}"
  volume_size = "${var.proxy_volume_size}"
  key_name = "${var.key_name}"
  key_file = "${var.key_file}"
  private_subnet_id = "${var.private_subnet_id}"
  private_security_group_id = "${var.private_security_group_id}"
  version = "${var.proxy_version}"

  server = "${var.server}"
  role = "suse_manager_proxy"
  mirror_public_name = "${var.mirror_public_name}"
  mirror_private_name = "${var.mirror_private_name}"
}

module "aws_proxy_host_group" {
  source = "../host_group"
  name = "${var.name_prefix}-minion"
  count = "${var.count}"
  host_count = "${var.minion_count}"
  region = "${var.region}"
  availability_zone = "${var.availability_zone}"

  amis = "${var.minion_amis}"
  instance_type = "${var.minion_instance_type}"
  volume_size = "${var.minion_volume_size}"
  key_name = "${var.key_name}"
  private_subnet_id = "${var.private_subnet_id}"
  private_security_group_id = "${var.private_security_group_id}"
  version = "${var.minion_version}"
  activation_key = "${var.activation_key}"

  servers = "${module.aws_proxy.private_names}"
  role = "minion"
  mirror_public_name = "${var.mirror_public_name}"
  mirror_private_name = "${var.mirror_private_name}"
}

output "proxy_private_names" {
  value = "${module.aws_proxy.private_names}"
}
