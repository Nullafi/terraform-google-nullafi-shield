# ------------------------------------------------------------------------------
# service-account module – outputs
# ------------------------------------------------------------------------------

output "email" {
  description = "Email of the service account."
  value       = google_service_account.main.email
}

output "member" {
  description = "IAM member string (serviceAccount:<email>)."
  value       = google_service_account.main.member
}

output "id" {
  description = "Fully-qualified ID of the service account."
  value       = google_service_account.main.id
}

output "name" {
  description = "Resource name of the service account."
  value       = google_service_account.main.name
}
