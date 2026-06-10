# ------------------------------------------------------------------------------
# compute-instance module – variables
# ------------------------------------------------------------------------------

variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "name" {
  description = "Name of the Compute Engine instance."
  type        = string
}

variable "machine_type" {
  description = "Compute Engine machine type (e.g. e2-standard-2)."
  type        = string
  default     = "e2-standard-2"
}

variable "zone" {
  description = "GCP zone for the VM."
  type        = string
}

variable "network_tags" {
  description = "Network tags applied to the VM (matched by firewall rules)."
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels applied to the VM."
  type        = map(string)
  default     = {}
}

variable "image" {
  description = "Boot disk image."
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "os_disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
  default     = 64
}

variable "subnetwork" {
  description = "ID or self link of the subnet to attach the VM to."
  type        = string
}

variable "nat_ip" {
  description = "Static external IP to attach to the VM (the access_config nat_ip)."
  type        = string
}

variable "service_account_email" {
  description = "Email of the service account the VM runs as."
  type        = string
}

variable "service_account_scopes" {
  description = "OAuth scopes for the VM's service account."
  type        = list(string)
  default     = ["cloud-platform"]
}

variable "startup_script" {
  description = "Rendered startup script written to the startup-script metadata key."
  type        = string
}

variable "extra_metadata" {
  description = "Additional instance metadata (e.g. ssh-keys) merged with startup-script."
  type        = map(string)
  default     = {}
}
