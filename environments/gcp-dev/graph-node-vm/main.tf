locals {
  suffix  = "graph-node"
  zone    = "us-central1-a"
  project = "unreal-465316"
  region  = "us-central1"
  labels = {
    environment = "dev"
  }
}

# get the managed ssl certificate for the load balancer
data "google_compute_ssl_certificate" "managed_ssl_certificate" {
  name    = "graph-node-tls-cert-2"
  project = local.project
}

module "graph-node-vm-arm" {
  count        = 0
  source       = "../../../modules/google/vm"
  suffix       = "arm-${local.suffix}"
  machine_type = "c4a-standard-2"
  zone         = local.zone
  tags         = ["graph-node"]
  public       = true
  project      = local.project
  image        = "ubuntu-os-cloud/ubuntu-2204-lts-arm64"
  boot_disk = {
    size_gb      = 10
    type         = "hyperdisk-balanced"
    architecture = "ARM64"
  }

  external_disk = {
    size_gb = 25
    type    = "hyperdisk-balanced"
  }
  labels = local.labels
}

# TODO: add some network rules to allow/restrict traffic to the vm to harden its security
module "graph-node-vm" {
  count        = 1
  source       = "../../../modules/google/vm"
  suffix       = local.suffix
  machine_type = "n2-standard-2"
  zone         = local.zone
  tags         = ["graph-node"]
  public       = true
  project      = local.project
  boot_disk = {
    size_gb = 10
    type    = "pd-balanced"
  }

  install_docker_on_boot = true
  mount_external_disk    = true
  external_disk = {
    size_gb = 25
    type    = "pd-balanced"
  }
  labels = local.labels
}

module "graph-node-instance-group" {
  count       = 1
  source      = "../../../modules/google/instance-group"
  suffix      = local.suffix
  description = "Instance group for graph node VMs"
  zone        = local.zone
  project     = local.project

  instances = [
    module.graph-node-vm[0].vm_instance.self_link
  ]

  named_ports = [
    {
      name = "graph-node-port"
      port = 8000
    }
  ]
}

# create a global static ip for the load balancer
module "graph-node-global-static-ip" {
  count   = 1
  source  = "../../../modules/google/static-ip"
  suffix  = local.suffix
  region  = "global"
  project = local.project
}

# create a load balancer with a managed cert
module "graph-node-lb" {
  count             = 1
  source            = "../../../modules/google/lb"
  suffix            = local.suffix
  project           = local.project
  static_ip_address = module.graph-node-global-static-ip[0].static_ip[0].self_link
  ssl_certificates  = [data.google_compute_ssl_certificate.managed_ssl_certificate.id]
  port_name         = "graph-node-port"
  frontend_protocol = "HTTPS" # Frontend: clients connect with HTTPS
  backend_protocol  = "HTTP"  # Backend: LB forwards HTTP to instances (SSL termination)
  health_check_port = 8000
  backends = [
    {
      group           = module.graph-node-instance-group[0].instance_group.self_link
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 1
      description     = "Graph node backend"
    }
  ]

  depends_on = [module.graph-node-global-static-ip]
}
