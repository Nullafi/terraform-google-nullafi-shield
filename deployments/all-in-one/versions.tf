terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

# Configure the Google provider here. The root module declares required_providers
# but leaves configuration to the caller, so this is the right place for it.
provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
  credentials = var.credentials_file != null ? file(var.credentials_file) : null
}
