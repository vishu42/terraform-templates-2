variable "suffix" {
  type = string
}

variable "machine_type" {
  type        = string
  description = "Machine type of the VM"
  default     = "e2-micro"
}

variable "zone" {
  type        = string
  description = "Zone of the VM"
}

variable "tags" {
  type        = list(string)
  description = "Tags of the VM"
}

variable "image" {
  type        = string
  description = "Image of the VM"
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "boot_disk" {
  type = object({
    size_gb      = number
    type         = string
    architecture = optional(string, "X86_64")
  })
  description = "Boot disk configuration"
  default = {
    size_gb      = 10
    type         = "pd-standard"
    architecture = "X86_64"
  }
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to all resources"
  default     = {}
}

variable "public" {
  type        = bool
  description = "Whether to assign a public IP to the VM"
  default     = false
}

variable "external_disk" {
  type = object({
    size_gb = number
    type    = string
  })
  description = "External disk configuration. Set to null to skip external disk creation. Disk name will be automatically generated as 'disk-{vm_name}'."
  default     = null
}

variable "project" {
  type    = string
  default = null
}

variable "install_docker_on_boot" {
  type        = bool
  description = "Whether to install docker on boot"
  default     = false
}

variable "mount_external_disk" {
  type        = bool
  description = "Whether to mount an external disk"
  default     = false
}
