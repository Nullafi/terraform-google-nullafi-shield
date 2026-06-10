# ------------------------------------------------------------------------------
# service-account module – variables
# ------------------------------------------------------------------------------

variable "account_id" {
  description = "Service account ID (the part before @)."
  type        = string
}

variable "display_name" {
  description = "Human-readable display name for the service account."
  type        = string
}

variable "project_id" {
  description = "GCP project ID (used for the optional dns.admin IAM binding)."
  type        = string
}

variable "grant_dns_admin" {
  description = "When true, grant the service account roles/dns.admin (for DNS-01 ACME challenges against Cloud DNS)."
  type        = bool
  default     = false
}
