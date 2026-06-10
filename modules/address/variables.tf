# ------------------------------------------------------------------------------
# address module – variables
# ------------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix for the address name."
  type        = string
}

variable "region" {
  description = "GCP region for the reserved address."
  type        = string
}
