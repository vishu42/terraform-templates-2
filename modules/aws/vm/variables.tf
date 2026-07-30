variable "name_suffix" {
  type    = string
  default = ""
}

variable "suffix" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "subnet_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "region" {
  type = string
}

variable "associate_public_ip_address" {
  type    = bool
  default = false
}

variable "root_block_device_size" {
  type    = number
  default = 8
  description = "The size of the root block device in GB"
}

variable "root_block_device_type" {
  type    = string
  default = null
  description = "The type of the root block device"
}

variable "ebs_block_device_size" {
  type    = number
  default = 8
  description = "The size of the ebs block device in GB"
}

variable "ebs_block_device_type" {
  type    = string
  default = "gp2"
  description = "The type of the ebs block device"
}

variable "public_key" {
  type = string
}

variable "install_docker_on_boot" {
  type    = bool
  default = false
}

variable "mount_external_disk_on_boot" {
  type    = bool
  default = false
}