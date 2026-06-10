module "nullafi_shield" {
  source = "../.."

  project_id = var.project_id
  region     = var.region
  zone       = var.zone
  name_prefix = var.name_prefix

  nullafi_license_key = var.nullafi_license_key
  proxy_mitm_cert     = var.proxy_mitm_cert
  proxy_mitm_key      = var.proxy_mitm_key
  elastic_password    = var.elastic_password

  machine_type    = var.machine_type
  os_disk_size_gb = var.os_disk_size_gb
  subnet_cidr     = var.subnet_cidr

  host_name           = var.host_name
  acme_challenge_type = var.acme_challenge_type
  acme_dns01_provider = var.acme_dns01_provider
  acme_dns01_env      = var.acme_dns01_env
  dns_managed_zone    = var.dns_managed_zone
  dns_wait_timeout    = var.dns_wait_timeout

  proxy_port        = var.proxy_port
  ssh_public_key    = var.ssh_public_key
  ssh_user          = var.ssh_user
  allowed_ssh_cidrs = var.allowed_ssh_cidrs

  shield_image   = var.shield_image
  squid_image    = var.squid_image
  activity_image = var.activity_image
  redis_image    = var.redis_image

  labels = var.labels
}
