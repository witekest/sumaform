variable "proxy_name" {
  description = "Symbolic name of the Proxy for terraform use"
  default = "proxy"
}

variable "region" {
  description = "Region where the instance is created"
  type = "string"
}

variable "availability_zone" {
  description = "Availability zone where the instance is created"
  type = "string"
}

variable "count"  {
  description = "Number of groups like this one"
  default = 1
}

variable "proxy_ami" {
  description = "AMI image for the Proxy in the configured region, see modules/aws/images"
  type = "string"
}

variable "proxy_instance_type" {
  description = "Instance type for the Proxy, see a list at: https://aws.amazon.com/ec2/instance-types/"
  default = "t2.small"
}

variable "proxy_volume_size" {
  description = "Size of the root volume in GiB for the Proxy"
  default = 50
}

variable "key_name" {
  description = "Name of the SSH key for the instance"
  type = "string"
}

variable "key_file" {
  description = "Path to the private SSH key"
  type = "string"
}

variable "private_subnet_id" {
  description = "ID of the private subnet, see modules/aws/network"
  type = "string"
}

variable "private_security_group_id" {
  description = "ID of the security group of the private subnet, see modules/aws/network"
  type = "string"
}

variable "proxy_version" {
  description = "Proxy product version (eg. 2.1-released, 3.0-nightly, head)"
  default = "3.1-nightly"
}

variable "server" {
  description = "Main server for the Proxy"
  default = "null"
}

variable "mirror_public_name" {
  description = "mirror's public DNS name"
  type = "string"
}

variable "mirror_private_name" {
  description = "mirror's private DNS name"
  type = "string"
}

variable "minion_count"  {
  description = "Number of minions in the group"
  default = 1
}

variable "autoscaling_group_count"  {
  description = "Number of autoscaling groups to create"
  default = 1
}

variable "minion_amis" {
  description = "AMI image list for the minions in the configured region, see modules/aws/images"
  type = "list"
}

variable "minion_instance_type" {
  description = "Instance type for the minions, see a list at: https://aws.amazon.com/ec2/instance-types/"
  default = "t2.nano"
}

variable "minion_volume_size" {
  description = "Size of the root volume in GiB for the minions"
  default = 10
}

variable "minion_version" {
  description = "minion product version (eg. 2.1-released, 3.0-nightly, head)"
  default = "3.1-nightly"
}

variable "activation_key" {
  description = "an Activation Key to be used when onboarding a minion"
  default = "null"
}

variable "name_prefix" {
  description = "A prefix for names of objects created by this module"
  default = "sumaform"
}
