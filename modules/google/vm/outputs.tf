output "vm_instance" {
  description = "The complete VM instance resource with all attributes"
  value       = google_compute_instance.vm
}

output "external_disk" {
  description = "The complete external disk resource with all attributes (null if no external disk configured)"
  value       = var.external_disk != null ? google_compute_disk.external[0] : null
}
