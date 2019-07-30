output "application_public_ip" {
  value = "${google_compute_global_forwarding_rule.dev.ip_address}"
}

