# ------------------------------------------------------------------------------
# firewall module – ingress rules for the Shield VM. GCP analog of the AWS
# instance security group.
#   - web rule: opens the public web/proxy ports to the internet.
#   - ssh rule: only created when allowed_ssh_cidrs is non-empty (otherwise SSH
#     stays closed and the GCP serial console / IAP remain available).
# Both rules target the given network tags so they apply only to the intended
# VM(s) rather than every instance on the network.
# ------------------------------------------------------------------------------

resource "google_compute_firewall" "web" {
  project   = var.project_id
  name      = "${var.name_prefix}-allow-web"
  network   = var.network
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = var.web_ports
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = var.target_tags
}

resource "google_compute_firewall" "ssh" {
  count = length(var.allowed_ssh_cidrs) > 0 ? 1 : 0

  project   = var.project_id
  name      = "${var.name_prefix}-allow-ssh"
  network   = var.network
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_cidrs
  target_tags   = var.target_tags
}
