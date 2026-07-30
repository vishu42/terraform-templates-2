variable "project" {
  description = "The GCP project ID where the static IP will be created"
  type        = string
}

variable "suffix" {
  description = "The suffix to append to the static IP name"
  type        = string
  default     = ""
}

variable "region" {
  description = "The region where the static IP will be created"
  type        = string
}

variable "address_type" {
  description = "The type of address to reserve. Either EXTERNAL or INTERNAL"
  type        = string
  default     = "EXTERNAL"
  validation {
    condition     = contains(["EXTERNAL", "INTERNAL"], var.address_type)
    error_message = "The address_type must be either EXTERNAL or INTERNAL."
  }
}

variable "network" {
  description = "The VPC network where the internal IP should be allocated (required for INTERNAL address_type)"
  type        = string
  default     = null
}

variable "subnetwork" {
  description = "The subnetwork where the internal IP should be allocated (optional for INTERNAL address_type)"
  type        = string
  default     = null
}

variable "address" {
  description = "The static IP address to reserve (optional, GCP will assign if not specified)"
  type        = string
  default     = null
}

variable "description" {
  description = "An optional description for the static IP"
  type        = string
  default     = "Static IP address"
}

variable "labels" {
  description = "A map of labels to assign to the static IP"
  type        = map(string)
  default     = {}
}