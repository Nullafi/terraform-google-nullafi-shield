variable "project_id" {
  description = "GCP project ID to deploy into."
  type        = string
}

variable "region" {
  description = "GCP region."
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "GCP zone for the VM. Must be within var.region."
  type        = string
  default     = "us-east1-b"
}

variable "credentials_file" {
  description = "Path to a GCP service-account key JSON file. Leave null to use Application Default Credentials."
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
  default     = "nullafi-aio"
}

variable "machine_type" {
  description = "Compute Engine machine type."
  type        = string
  default     = "e2-standard-2"
}

variable "os_disk_size_gb" {
  description = "Size of the VM boot disk in GB."
  type        = number
  default     = 64
}

variable "subnet_cidr" {
  description = "CIDR range for the single VM subnet."
  type        = string
  default     = "10.0.0.0/24"
}

variable "nullafi_license_key" {
  description = "Nullafi license key string."
  type        = string
  default     = null
  sensitive   = true
}

variable "proxy_mitm_cert" {
  description = "Path to the Squid MITM certificate (PEM)."
  type        = string
  default     = null
}

variable "proxy_mitm_key" {
  description = "Path to the Squid MITM private key (PEM)."
  type        = string
  default     = null
  sensitive   = true
}

variable "elastic_password" {
  description = "Password for Elasticsearch."
  type        = string
  default     = "elastic"
  sensitive   = true
}

variable "proxy_port" {
  description = "External port for the Squid proxy."
  type        = number
  default     = 44509
}

variable "host_name" {
  description = "Public hostname for Shield. When set, enables HTTPS via Let's Encrypt."
  type        = string
  default     = null
}

variable "acme_challenge_type" {
  description = "ACME challenge type: HTTP-01, TLS-ALPN-01, or DNS-01."
  type        = string
  default     = "TLS-ALPN-01"
}

variable "acme_dns01_provider" {
  description = "DNS provider for DNS-01 (e.g. gcloud, cloudflare)."
  type        = string
  default     = null
}

variable "acme_dns01_env" {
  description = "Credentials env vars for the DNS-01 provider."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "dns_managed_zone" {
  description = "Cloud DNS managed-zone resource name. When set with host_name, auto-creates the A record and grants dns.admin to the VM."
  type        = string
  default     = null
}

variable "dns_wait_timeout" {
  description = "Seconds to wait for DNS to resolve before starting containers."
  type        = number
  default     = 900
}

variable "ssh_public_key" {
  description = "SSH public key to install on the VM. Leave null to disable key-based SSH."
  type        = string
  default     = null
}

variable "ssh_user" {
  description = "SSH username."
  type        = string
  default     = "nullafi"
}

variable "allowed_ssh_cidrs" {
  description = "CIDRs allowed SSH access. Empty disables SSH."
  type        = list(string)
  default     = []
}

variable "shield_image" {
  description = "Shield container image."
  type        = string
  default     = "public.ecr.aws/nullafi/shield:latest"
}

variable "squid_image" {
  description = "Squid proxy container image."
  type        = string
  default     = "public.ecr.aws/nullafi/proxy:latest"
}

variable "activity_image" {
  description = "Elasticsearch container image."
  type        = string
  default     = "docker.elastic.co/elasticsearch/elasticsearch:8.7.0"
}

variable "redis_image" {
  description = "Redis container image."
  type        = string
  default     = "redis:6.2-alpine"
}

variable "labels" {
  description = "Labels applied to all resources."
  type        = map(string)
  default     = {}
}
