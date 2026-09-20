variable "name" {
  type        = string
  description = "Name prefix for all resources. Use a different value per deployment to run multiple instances of this template."
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment name, used for tagging"
}

variable "region" {
  type        = string
  default     = "eu-central-1"
  description = "AWS region to deploy into"
}

variable "availability_zones" {
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
  description = "The two availability zones the ALB spans. Must be in var.region."
}

variable "ami_id" {
  type        = string
  default     = "ami-02003f9f0fde924ea"
  description = "AMI for the supabase VM"
}

variable "instance_type" {
  type    = string
  default = "t3.large"
}

variable "root_block_device_size" {
  type        = number
  default     = 20
  description = "Root disk size in GB"
}

variable "ebs_block_device_size" {
  type        = number
  default     = 25
  description = "External data disk size in GB"
}

variable "app_port" {
  type        = number
  default     = 8000
  description = "Port the supabase gateway listens on"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Extra tags merged into every resource"
}
