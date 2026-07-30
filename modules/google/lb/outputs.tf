output "load_balancer" {
  description = "Complete Layer 7 Application Load Balancer resources"
  value = {
    health_check            = google_compute_health_check.default
    backend_service         = google_compute_backend_service.default
    url_map                 = google_compute_url_map.default
    managed_ssl_certificate = length(var.managed_ssl_certificate_domains) > 0 ? google_compute_managed_ssl_certificate.default[0] : null
    # http_proxy              = var.frontend_protocol == "HTTP" ? google_compute_target_http_proxy.default[0] : null
    # https_proxy             = var.frontend_protocol == "HTTPS" ? google_compute_target_https_proxy.default[0] : null
    # http_forwarding_rule    = var.frontend_protocol == "HTTP" ? google_compute_global_forwarding_rule.http[0] : null
    # https_forwarding_rule   = var.frontend_protocol == "HTTPS" ? google_compute_global_forwarding_rule.https[0] : null
  }
} 