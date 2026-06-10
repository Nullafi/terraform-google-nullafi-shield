# ------------------------------------------------------------------------------
# firewall module – outputs
# ------------------------------------------------------------------------------

output "web_firewall_name" {
  description = "Name of the web ingress firewall rule."
  value       = google_compute_firewall.web.name
}

output "ssh_firewall_name" {
  description = "Name of the SSH ingress firewall rule (null when SSH is disabled)."
  value       = length(google_compute_firewall.ssh) > 0 ? google_compute_firewall.ssh[0].name : null
}
