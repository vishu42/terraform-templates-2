resource "google_compute_disk" "external" {
  count = var.external_disk != null ? 1 : 0

  name    = "disk-${var.suffix}"
  type    = var.external_disk.type
  size    = var.external_disk.size_gb
  zone    = var.zone
  labels  = var.labels
  project = var.project
}

resource "google_compute_instance" "vm" {
  name         = "vm-${var.suffix}"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = var.tags
  labels       = var.labels
  project      = var.project

  boot_disk {
    initialize_params {
      image        = var.image
      size         = var.boot_disk.size_gb
      type         = var.boot_disk.type
      architecture = var.boot_disk.architecture
    }
  }

  metadata_startup_script = join("", [
    file("${path.module}/scripts/startup.sh"),
    "\n\n# Execute startup script with Terraform-provided flags\n",
    "main",
    var.install_docker_on_boot ? " --install-docker" : "",
    var.mount_external_disk ? " --mount-external-disk" : "",
    "\n"
  ])

  dynamic "attached_disk" {
    for_each = var.external_disk != null ? [1] : []
    content {
      source = google_compute_disk.external[0].id
    }
  }

  network_interface {
    network = "default"

    dynamic "access_config" {
      for_each = var.public ? [1] : []
      content {
        // Ephemeral IP
      }
    }
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}
