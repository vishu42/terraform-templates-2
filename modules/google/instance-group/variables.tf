variable "suffix" {
  type = string
}

variable "description" {
  type        = string
  description = "Description of the instance group"
  default     = ""
}

variable "zone" {
  type        = string
  description = "Zone where the instance group will be created"
}

variable "project" {
  type        = string
  description = "Project ID where the instance group will be created"
  default     = null
}

variable "instances" {
  type        = list(string)
  description = "List of instance self_links to add to the group"
  default     = []
}

variable "named_ports" {
  type = list(object({
    name = string
    port = number
  }))
  description = "Named ports for the instance group"
  default     = []
} 