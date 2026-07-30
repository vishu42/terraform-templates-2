resource "google_compute_address" "static_ip" {
  count        = var.region != "global" ? 1 : 0
  name         = "${var.address_type == "EXTERNAL" ? "static-ip" : "internal-static-ip"}-${var.suffix}"
  project      = var.project
  region       = var.region
  address_type = var.address_type
  description  = var.description
  
  # Fields for INTERNAL addresses
  network    = var.address_type == "INTERNAL" ? var.network : null
  subnetwork = var.address_type == "INTERNAL" ? var.subnetwork : null
  
  # Optional specific address
  address = var.address

  labels = var.labels
}

resource "google_compute_global_address" "static_ip" {
  count        = var.region == "global" ? 1 : 0
  name         = "global-static-ip-${var.suffix}"
  project      = var.project
  address_type = "EXTERNAL"
  description  = var.description
  address      = var.address
  labels       = var.labels
}


