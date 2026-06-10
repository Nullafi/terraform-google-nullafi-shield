# ------------------------------------------------------------------------------
# Nullafi Shield – single Compute Engine VM running docker-compose. The full
# 6-container stack (shield-web-ui, shield-icap, shield-alert, squid, activity,
# redis) runs on one VM behind a static external IP.
#
# Composed from reusable submodules under ./modules:
#   network          – custom-mode VPC + subnet
#   firewall         – web (80/443/proxy) + optional SSH ingress rules
#   address          – reserved static external IP
#   service-account  – dedicated VM SA (+ optional dns.admin for DNS-01)
#   dns-record       – optional Cloud DNS A record
#   compute-instance – the VM, running the startup script below
#
# Architectural notes:
#   - One custom-mode VPC with a single subnet. The VM gets a static external IP
#     directly, so outbound goes straight out — no Cloud NAT needed.
#   - All TLS terminates *inside* the shield-web-ui container via Let's Encrypt
#     ACME. There is no load balancer and no Google-managed certificate — the
#     external IP is a plain L4 passthrough.
#   - The startup script writes /opt/nullafi/{.env, docker-compose.yml,
#     license.key, mitm.crt/key} and runs `docker compose up -d`.
# ------------------------------------------------------------------------------

locals {
  has_mitm_cert   = var.proxy_mitm_cert != null && var.proxy_mitm_key != null
  has_license_key = var.nullafi_license_key != null
  has_domain      = var.host_name != null

  host_name = var.host_name != null ? var.host_name : module.address.address

  mitm_cert = local.has_mitm_cert ? file(var.proxy_mitm_cert) : ""
  mitm_key  = local.has_mitm_cert ? file(nonsensitive(var.proxy_mitm_key)) : ""

  manage_dns = var.dns_managed_zone != null && var.host_name != null

  network_tag = "${var.name_prefix}-vm"

  acme_dns01_env = local.manage_dns ? merge({ GCE_PROJECT = var.project_id }, var.acme_dns01_env) : var.acme_dns01_env

  ssh_metadata = var.ssh_public_key != null ? { ssh-keys = "${var.ssh_user}:${var.ssh_public_key}" } : {}

  startup_script = templatefile("${path.module}/startup-script.sh.tftpl", {
    host_name           = local.host_name
    shield_image        = var.shield_image
    squid_image         = var.squid_image
    activity_image      = var.activity_image
    redis_image         = var.redis_image
    elastic_password    = var.elastic_password
    proxy_port          = var.proxy_port
    license_key         = local.has_license_key ? nonsensitive(var.nullafi_license_key) : ""
    has_license_key     = local.has_license_key
    has_mitm_cert       = local.has_mitm_cert
    mitm_cert           = local.mitm_cert
    mitm_key            = local.has_mitm_cert ? nonsensitive(local.mitm_key) : ""
    has_domain          = local.has_domain
    acme_challenge_type = var.acme_challenge_type
    acme_dns01_provider = var.acme_dns01_provider
    acme_dns01_env      = local.acme_dns01_env
    dns_wait_iterations = var.dns_wait_timeout / 10
  })
}

# ------------------------------------------------------------------------------
# Networking
# ------------------------------------------------------------------------------

module "network" {
  source = "./modules/network"

  project_id  = var.project_id
  name_prefix = var.name_prefix
  subnet_cidr = var.subnet_cidr
  region      = var.region
}

# ------------------------------------------------------------------------------
# Firewall
# ------------------------------------------------------------------------------

module "firewall" {
  source = "./modules/firewall"

  project_id        = var.project_id
  name_prefix       = var.name_prefix
  network           = module.network.network_id
  target_tags       = [local.network_tag]
  web_ports         = ["80", "443", tostring(var.proxy_port)]
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
}

# ------------------------------------------------------------------------------
# Static external IP
# ------------------------------------------------------------------------------

module "address" {
  source = "./modules/address"

  project_id  = var.project_id
  name_prefix = var.name_prefix
  region      = var.region
}

# ------------------------------------------------------------------------------
# Service account
# ------------------------------------------------------------------------------

module "service_account" {
  source = "./modules/service-account"

  account_id      = "${var.name_prefix}-vm"
  display_name    = "Nullafi Shield all-in-one VM"
  project_id      = var.project_id
  grant_dns_admin = local.manage_dns
}

# ------------------------------------------------------------------------------
# Optional Cloud DNS A record
# ------------------------------------------------------------------------------

module "dns" {
  source = "./modules/dns-record"
  count  = local.manage_dns ? 1 : 0

  host_name    = var.host_name
  managed_zone = var.dns_managed_zone
  ip_address   = module.address.address
}

# ------------------------------------------------------------------------------
# Compute Engine VM
# ------------------------------------------------------------------------------

module "compute_instance" {
  source = "./modules/compute-instance"

  project_id            = var.project_id
  name                  = "${var.name_prefix}-vm"
  machine_type          = var.machine_type
  zone                  = var.zone
  network_tags          = [local.network_tag]
  labels                = var.labels
  os_disk_size_gb       = var.os_disk_size_gb
  subnetwork            = module.network.subnetwork_id
  nat_ip                = module.address.address
  service_account_email = module.service_account.email
  extra_metadata        = local.ssh_metadata
  startup_script        = local.startup_script
}
