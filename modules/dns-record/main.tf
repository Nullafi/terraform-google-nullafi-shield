# ------------------------------------------------------------------------------
# dns-record module – a single A record in an existing Cloud DNS managed zone.
# GCP analog of the AWS Route53 record. The managed zone must already exist.
# ------------------------------------------------------------------------------

resource "google_dns_record_set" "main" {
  name         = "${trimsuffix(var.host_name, ".")}."
  managed_zone = var.managed_zone
  type         = "A"
  ttl          = var.ttl
  rrdatas      = [var.ip_address]
}
