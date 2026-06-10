# ------------------------------------------------------------------------------
# compute-instance module – outputs
# ------------------------------------------------------------------------------

output "id" {
  description = "Fully-qualified ID of the instance."
  value       = google_compute_instance.main.id
}

output "name" {
  description = "Name of the instance."
  value       = google_compute_instance.main.name
}

output "self_link" {
  description = "Self link of the instance."
  value       = google_compute_instance.main.self_link
}

output "internal_ip" {
  description = "Internal IP of the instance's primary NIC."
  value       = google_compute_instance.main.network_interface[0].network_ip
}

output "external_ip" {
  description = "External IP attached to the instance."
  value       = google_compute_instance.main.network_interface[0].access_config[0].nat_ip
}
