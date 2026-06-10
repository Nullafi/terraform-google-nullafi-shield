# ------------------------------------------------------------------------------
# network module – variables
# ------------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix for resource names (VPC and subnet)."
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet."
  type        = string
  default     = "10.0.0.0/24"
}

variable "region" {
  description = "GCP region for the subnet."
  type        = string
}
