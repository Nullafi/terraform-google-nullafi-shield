# ------------------------------------------------------------------------------
# service-account module – a dedicated service account for the VM, plus an
# optional roles/dns.admin grant. The grant is only needed when the in-container
# ACME client solves DNS-01 challenges against Cloud DNS using the VM's ADC.
# ------------------------------------------------------------------------------

resource "google_service_account" "main" {
  account_id   = var.account_id
  display_name = var.display_name
}

resource "google_project_iam_member" "dns_admin" {
  count   = var.grant_dns_admin ? 1 : 0
  project = var.project_id
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.main.email}"
}
