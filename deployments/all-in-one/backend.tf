# Remote state backend (Google Cloud Storage). The bucket is provided via
# -backend-config at init time, e.g.:
#   terraform init -backend-config="bucket=nullafi-tfstate-mdc-defender3"
# Delete this file to fall back to local state.
terraform {
  backend "gcs" {
    prefix = "all-in-one"
  }
}
