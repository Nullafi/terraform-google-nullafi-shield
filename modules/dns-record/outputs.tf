# ------------------------------------------------------------------------------
# dns-record module – outputs
# ------------------------------------------------------------------------------

output "name" {
  description = "The FQDN of the created record (with trailing dot)."
  value       = google_dns_record_set.main.name
}
