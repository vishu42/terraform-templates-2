# Configuration Logic
locals {
  # Determine which SSL certificates to use
  ssl_certificates = length(var.managed_ssl_certificate_domains) > 0 ? [google_compute_managed_ssl_certificate.default[0].id] : var.ssl_certificates
}

# Google Managed SSL Certificate
resource "google_compute_managed_ssl_certificate" "default" {
  count       = length(var.managed_ssl_certificate_domains) > 0 ? 1 : 0
  name        = "${var.name_prefix}-managed-ssl-cert-${var.suffix}"
  project     = var.project
  description = "Google Managed SSL certificate for load balancer"

  managed {
    domains = var.managed_ssl_certificate_domains
  }
}

# Health Check
resource "google_compute_health_check" "default" {
  name               = "${var.name_prefix}-health-check-${var.suffix}"
  project            = var.project
  description        = "Health check for load balancer"
  timeout_sec        = var.health_check_timeout
  check_interval_sec = var.health_check_interval

  dynamic "http_health_check" {
    for_each = var.backend_protocol == "HTTP" ? [1] : []
    content {
      port         = var.health_check_port
      request_path = var.health_check_path
    }
  }

  dynamic "https_health_check" {
    for_each = var.backend_protocol == "HTTPS" ? [1] : []
    content {
      port         = var.health_check_port
      request_path = var.health_check_path
    }
  }
}

# Backend Service
resource "google_compute_backend_service" "default" {
  name                  = "${var.name_prefix}-backend-${var.suffix}"
  project               = var.project
  description           = "Backend service for load balancer"
  protocol              = var.backend_protocol
  port_name             = var.port_name
  timeout_sec           = var.backend_timeout
  enable_cdn            = var.enable_cdn
  load_balancing_scheme = "EXTERNAL"

  health_checks = [google_compute_health_check.default.id]

  dynamic "backend" {
    for_each = var.backends
    content {
      group           = backend.value.group
      balancing_mode  = backend.value.balancing_mode
      capacity_scaler = backend.value.capacity_scaler
      description     = backend.value.description
    }
  }

  dynamic "cdn_policy" {
    for_each = var.enable_cdn ? [1] : []
    content {
      cache_mode        = var.cdn_cache_mode
      default_ttl       = var.cdn_default_ttl
      max_ttl           = var.cdn_max_ttl
      negative_caching  = var.cdn_negative_caching
      serve_while_stale = var.cdn_serve_while_stale
    }
  }
}

# URL Map
resource "google_compute_url_map" "default" {
  name            = "${var.name_prefix}-url-map-${var.suffix}"
  project         = var.project
  description     = "URL map for load balancer"
  default_service = google_compute_backend_service.default.id

  dynamic "host_rule" {
    for_each = var.host_rules
    content {
      hosts        = host_rule.value.hosts
      path_matcher = host_rule.value.path_matcher
    }
  }

  dynamic "path_matcher" {
    for_each = var.path_matchers
    content {
      name            = path_matcher.value.name
      default_service = path_matcher.value.default_service

      dynamic "path_rule" {
        for_each = path_matcher.value.path_rules
        content {
          paths   = path_rule.value.paths
          service = path_rule.value.service
        }
      }
    }
  }
}

# Target HTTP Proxy (for HTTP)
resource "google_compute_target_http_proxy" "default" {
  count   = var.frontend_protocol == "HTTP" ? 1 : 0
  name    = "${var.name_prefix}-http-proxy-${var.suffix}"
  project = var.project
  url_map = google_compute_url_map.default.id
}

# Target HTTPS Proxy (for HTTPS)
resource "google_compute_target_https_proxy" "default" {
  count            = var.frontend_protocol == "HTTPS" ? 1 : 0
  name             = "${var.name_prefix}-https-proxy-${var.suffix}"
  project          = var.project
  url_map          = google_compute_url_map.default.id
  ssl_certificates = local.ssl_certificates
}

# Forwarding Rule
resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name                  = "${var.name_prefix}-forwarding-rule-${var.suffix}"
  project               = var.project
  target                = var.frontend_protocol == "HTTP" ? google_compute_target_http_proxy.default[0].id : google_compute_target_https_proxy.default[0].id
  ip_protocol           = "TCP"
  port_range            = 443
  ip_address            = var.static_ip_address
  network_tier          = "PREMIUM"
  load_balancing_scheme = "EXTERNAL"
}
