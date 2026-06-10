# ------------------------------------------------------------------------------
# address module – a reserved regional external IP. GCP analog of an AWS EIP /
# Azure static public IP. Reserving it as a standalone resource lets DNS point at
# the IP before (and independently of) the VM that consumes it.
# ------------------------------------------------------------------------------

resource "google_compute_address" "main" {
  name         = "${var.name_prefix}-ip"
  region       = var.region
  address_type = "EXTERNAL"
}
