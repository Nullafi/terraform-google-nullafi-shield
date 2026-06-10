# ------------------------------------------------------------------------------
# address module – outputs
# ------------------------------------------------------------------------------

output "address" {
  description = "The reserved external IP address."
  value       = google_compute_address.main.address
}

output "self_link" {
  description = "Self link of the reserved address."
  value       = google_compute_address.main.self_link
}

output "name" {
  description = "Name of the reserved address."
  value       = google_compute_address.main.name
}
