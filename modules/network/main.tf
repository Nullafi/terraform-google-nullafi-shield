# ------------------------------------------------------------------------------
# network module – custom-mode VPC + a single regional subnet. GCP analog of the
# AWS vpc module (minus NAT/IGW, which are implicit on GCP). Egress goes straight
# out via the VM's external IP, so no Cloud NAT is created here.
# ------------------------------------------------------------------------------

resource "google_compute_network" "main" {
  project                 = var.project_id
  name                    = "${var.name_prefix}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  project       = var.project_id
  name          = "${var.name_prefix}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id

  # Let instances reach Google APIs over internal IPs without a public route.
  private_ip_google_access = true

  # VPC flow logs for network observability.
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}
