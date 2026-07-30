# Basic Configuration
variable "project" {
  description = "The GCP project ID where the load balancer will be created"
  type        = string
}

variable "name_prefix" {
  description = "The prefix for all load balancer resource names"
  type        = string
  default     = "lb"
}

variable "suffix" {
  type        = string
  default     = ""
  description = <<EOT
    The suffix to append to all resource names
    ```hcl
    suffix = "dev"
    ```
    EOT
}

variable "frontend_protocol" {
  description = "The frontend protocol for the load balancer (HTTP or HTTPS) - what clients connect with"
  type        = string
  default     = "HTTP"
  validation {
    condition     = contains(["HTTP", "HTTPS"], var.frontend_protocol)
    error_message = "Frontend protocol must be either HTTP or HTTPS."
  }
}

variable "backend_protocol" {
  description = "The backend protocol for health checks and backend service (HTTP or HTTPS) - what load balancer uses to talk to instances"
  type        = string
  default     = "HTTP"
  validation {
    condition     = contains(["HTTP", "HTTPS"], var.backend_protocol)
    error_message = "Backend protocol must be either HTTP or HTTPS."
  }
}

variable "static_ip_address" {
  description = "Static IP address for the load balancer (optional)"
  type        = string
  default     = null
}

# Health Check Configuration
variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 5
}

variable "health_check_port" {
  description = "Port for health check"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Path for health check"
  type        = string
  default     = "/"
}

# Backend Service Configuration
variable "port_name" {
  description = "Named port for the backend service"
  type        = string
}

variable "backend_timeout" {
  description = "Backend service timeout in seconds"
  type        = number
  default     = 30
}

variable "backends" {
  description = <<EOT
    List of backend configurations
    ```hcl
    backends = [
    {
      group = module.graph-node-instance-group[0].instance_group.self_link
      balancing_mode = "UTILIZATION" #Possible values are: UTILIZATION, RATE, CONNECTION, CUSTOM_METRICS.
      capacity_scaler = 1
      description = "Graph node backend"
    }
    ]
    EOT
  type = list(object({
    group           = string
    balancing_mode  = string
    capacity_scaler = number
    description     = string
  }))
}

# CDN Configuration
variable "enable_cdn" {
  description = "Enable Cloud CDN for the backend service"
  type        = bool
  default     = false
}

variable "cdn_cache_mode" {
  description = "CDN cache mode"
  type        = string
  default     = "CACHE_ALL_STATIC"
}

variable "cdn_default_ttl" {
  description = "CDN default TTL in seconds"
  type        = number
  default     = 3600
}

variable "cdn_max_ttl" {
  description = "CDN maximum TTL in seconds"
  type        = number
  default     = 86400
}

variable "cdn_negative_caching" {
  description = "Enable CDN negative caching"
  type        = bool
  default     = false
}

variable "cdn_serve_while_stale" {
  description = "CDN serve while stale in seconds"
  type        = number
  default     = 86400
}

# URL Map Configuration
variable "host_rules" {
  description = "List of host rules for the URL map"
  type = list(object({
    hosts        = list(string)
    path_matcher = string
  }))
  default = []
}

variable "path_matchers" {
  description = "List of path matchers for the URL map"
  type = list(object({
    name            = string
    default_service = string
    path_rules = list(object({
      paths   = list(string)
      service = string
    }))
  }))
  default = []
}

# SSL Certificate Configuration
variable "ssl_certificates" {
  description = "List of existing SSL certificate URLs for HTTPS load balancer (mutually exclusive with managed_ssl_certificate_domains)"
  type        = list(string)
  default     = []
}

variable "managed_ssl_certificate_domains" {
  description = "List of domains for Google Managed SSL certificate (mutually exclusive with ssl_certificates)"
  type        = list(string)
  default     = []
} 