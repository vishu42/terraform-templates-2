resource "google_compute_instance_group" "group" {
  name        = "ig-${var.suffix}"
  description = var.description
  zone        = var.zone
  project     = var.project

  instances = var.instances

  dynamic "named_port" {
    for_each = var.named_ports
    content {
      name = named_port.value.name
      port = named_port.value.port
    }
  }
}
