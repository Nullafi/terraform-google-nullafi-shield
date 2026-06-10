# ------------------------------------------------------------------------------
# firewall module – variables
# ------------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix for firewall rule names."
  type        = string
}

variable "network" {
  description = "ID or self link of the VPC network the rules attach to."
  type        = string
}

variable "target_tags" {
  description = "Network tags the rules apply to (the VM(s) carrying these tags)."
  type        = list(string)
}

variable "web_ports" {
  description = "TCP ports opened to the internet (e.g. 80, 443, and the Squid proxy port)."
  type        = list(string)
  default     = ["80", "443"]
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed SSH (port 22). Empty list disables the SSH rule entirely."
  type        = list(string)
  default     = []
}
