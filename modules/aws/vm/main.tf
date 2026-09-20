resource "aws_key_pair" "key_pair" {
  key_name   = "vm-${var.suffix}"
  public_key = var.public_key
}

resource "aws_instance" "vm" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  region                      = var.region
  associate_public_ip_address = var.associate_public_ip_address
  subnet_id                   = var.subnet_id
  key_name                    = aws_key_pair.key_pair.key_name
  user_data                   = join("", [
    file("${path.module}/../../../scripts/startup.sh"),
    "\n\n# Execute startup script with Terraform-provided flags\n",
    "main",
    var.install_docker_on_boot ? " --install-docker" : "",
    var.mount_external_disk_on_boot ? " --mount-external-disk" : "",
    "\n"
  ])

  tags = merge(var.tags, {
    Name = "vm-${var.suffix}"
  })

  root_block_device {
    volume_size = var.root_block_device_size
    volume_type = var.root_block_device_type
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = var.ebs_block_device_size
    volume_type = var.ebs_block_device_type
  }
}
