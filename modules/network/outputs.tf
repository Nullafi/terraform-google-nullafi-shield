# ------------------------------------------------------------------------------
# network module – outputs
# ------------------------------------------------------------------------------

output "network_id" {
  description = "ID of the VPC network."
  value       = google_compute_network.main.id
}

output "network_self_link" {
  description = "Self link of the VPC network."
  value       = google_compute_network.main.self_link
}

output "network_name" {
  description = "Name of the VPC network."
  value       = google_compute_network.main.name
}

output "subnetwork_id" {
  description = "ID of the subnet."
  value       = google_compute_subnetwork.main.id
}

output "subnetwork_self_link" {
  description = "Self link of the subnet."
  value       = google_compute_subnetwork.main.self_link
}

output "subnetwork_name" {
  description = "Name of the subnet."
  value       = google_compute_subnetwork.main.name
}
