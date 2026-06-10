# ------------------------------------------------------------------------------
# dns-record module – variables
# ------------------------------------------------------------------------------

variable "host_name" {
  description = "Fully-qualified hostname for the A record (with or without trailing dot)."
  type        = string
}

variable "managed_zone" {
  description = "Cloud DNS managed-zone resource name (not the DNS name)."
  type        = string
}

variable "ip_address" {
  description = "IPv4 address the A record points to."
  type        = string
}

variable "ttl" {
  description = "Record TTL in seconds."
  type        = number
  default     = 60
}
