locals {
  suffix  = "supabase"
  zone    = "us-central1-a"
  project = "unreal-465316"
  region  = "us-central1"
  labels = {
    environment = "dev"
  }
}

module "supabase-vm" {
  count        = 0
  source       = "../../../modules/google/vm"
  suffix       = local.suffix
  machine_type = "n2-standard-2"
  zone         = local.zone
  tags         = ["supabase"]
  public       = true
  project      = local.project
  boot_disk = {
    size_gb = 10
    type    = "pd-balanced"
  }
  external_disk = {
    size_gb = 25
    type    = "pd-balanced"
  }
  labels                 = local.labels
  install_docker_on_boot = true
  mount_external_disk    = true
}
