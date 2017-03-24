module "minion-swarm" {
  source = "../host"
  base_configuration = "${var.base_configuration}"
  name = "${var.name}"
  image = "sles12sp1"
  count = "${var.count}"
  memory = "${var.memory}"
  vcpu = "${var.vcpu}"
  running = "${var.running}"
  mac = "${var.mac}"
  additional_repos = "${var.additional_repos}"
  additional_packages = "${var.additional_packages}"
  grains = <<EOF

version: 3-stable
package-mirror: ${var.base_configuration["package_mirror"]}
server: ${var.server_configuration["hostname"]}
role: minion-swarm
minion-count: ${var.minion-count}
start-delay: ${var.start-delay}
swap_file_size: ${var.swap_file_size}

EOF
}

output "configuration" {
  value = "${module.minion-swarm.configuration}"
}