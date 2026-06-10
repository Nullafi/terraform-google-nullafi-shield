variable "project_id" {
  description = "GCP project ID to deploy into."
  type        = string
}

variable "region" {
  description = "GCP region (e.g. us-east1)."
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "GCP zone for the VM (e.g. us-east1-b). Must be within var.region."
  type        = string
  default     = "us-east1-b"
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
  default     = "nullafi-aio"
}

variable "machine_type" {
  description = "Compute Engine machine type. e2-standard-2 (2 vCPU / 8 GB) is the cost-friendly default. Use e2-standard-4 for steady-state."
  type        = string
  default     = "e2-standard-2"
}

variable "host_name" {
  description = "Public hostname for Shield (NULLAFI_HTTP_CUSTOM_DOMAIN). When null, the VM's static external IP is used as the host name."
  type        = string
  default     = null
}

variable "subnet_cidr" {
  description = "CIDR range for the single VM subnet."
  type        = string
  default     = "10.0.0.0/24"
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed SSH access on port 22. Empty list disables SSH (the GCP serial console and IAP remain available)."
  type        = list(string)
  default     = []
}

variable "ssh_user" {
  description = "OS login username seeded into instance metadata when ssh_public_key is set."
  type        = string
  default     = "nullafi"
}

variable "ssh_public_key" {
  description = "SSH public key (ssh-rsa / ssh-ed25519) added to the VM for var.ssh_user. Leave null to rely on OS Login / serial console only."
  type        = string
  default     = null
}

variable "os_disk_size_gb" {
  description = "Size of the VM boot disk in GB."
  type        = number
  default     = 64
}

# ------------------------------------------------------------------------------
# Container images
# ------------------------------------------------------------------------------

variable "shield_image" {
  description = "Shield container image (used for web-ui, icap, and alert modes)."
  type        = string
  default     = "public.ecr.aws/nullafi/shield:latest"
}

variable "squid_image" {
  description = "Squid proxy container image."
  type        = string
  default     = "public.ecr.aws/nullafi/proxy:latest"
}

variable "activity_image" {
  description = "Elasticsearch container image for Activity."
  type        = string
  default     = "docker.elastic.co/elasticsearch/elasticsearch:8.7.0"
}

variable "redis_image" {
  description = "Redis container image."
  type        = string
  default     = "redis:6.2-alpine"
}

# ------------------------------------------------------------------------------
# Secrets and certificates
# ------------------------------------------------------------------------------

variable "nullafi_license_key" {
  description = "Nullafi license key string. Written to /opt/nullafi/license.key on the VM."
  type        = string
  default     = null
  sensitive   = true
}

variable "proxy_mitm_cert" {
  description = "Path to the MITM CA certificate (PEM). Use your existing CA cert if available; Nullafi can provide one if not."
  type        = string
  default     = null
}

variable "proxy_mitm_key" {
  description = "Path to the MITM CA private key (PEM). Must match proxy_mitm_cert."
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

variable "acme_challenge_type" {
  description = "ACME challenge type for Let's Encrypt. HTTP-01 / TLS-ALPN-01 need DNS to point at the VM's external IP before HTTPS will activate. DNS-01 requires the chosen provider credentials."
  type        = string
  default     = "TLS-ALPN-01"

  validation {
    condition     = contains(["HTTP-01", "TLS-ALPN-01", "DNS-01"], var.acme_challenge_type)
    error_message = "acme_challenge_type must be one of: HTTP-01, TLS-ALPN-01, DNS-01"
  }
}

variable "acme_dns01_provider" {
  description = "DNS provider name for DNS-01 (e.g. gcloud for Google Cloud DNS, cloudflare). Only used when acme_challenge_type is DNS-01."
  type        = string
  default     = null
}

variable "acme_dns01_env" {
  description = "Environment variables for DNS-01 provider credentials. For Cloud DNS via the VM's service account, GCE_PROJECT is set automatically when dns_managed_zone is provided."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "dns_managed_zone" {
  description = "Cloud DNS managed-zone name (resource name, not DNS name). When set together with host_name, Terraform auto-creates the A record and grants the VM's service account dns.admin."
  type        = string
  default     = null
}

variable "dns_wait_timeout" {
  description = "Seconds to wait for DNS to resolve to the VM's external IP before starting containers. Only applies when host_name is set."
  type        = number
  default     = 900
}

variable "labels" {
  description = "Labels applied to all resources that support them."
  type        = map(string)
  default     = {}
}
