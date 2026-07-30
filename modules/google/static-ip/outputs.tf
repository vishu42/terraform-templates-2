output "static_ip" {
  description = "The complete static IP resource"
  value       = var.region == "global" ? google_compute_global_address.static_ip : google_compute_address.static_ip
} 