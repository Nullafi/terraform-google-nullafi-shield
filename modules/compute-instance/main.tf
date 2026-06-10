# ------------------------------------------------------------------------------
# compute-instance module – a single Compute Engine VM with a static external IP
# attached, running a caller-supplied startup script. GCP analog of the AWS
# aws_instance. The startup script (and image) are first-boot-only, so both are
# in ignore_changes — roll new container images in-VM rather than rebuilding.
# ------------------------------------------------------------------------------

resource "google_compute_instance" "main" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = var.network_tags
  labels       = var.labels

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.os_disk_size_gb
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = var.subnetwork

    access_config {
      nat_ip = var.nat_ip
    }
  }

  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }

  metadata = merge(
    var.extra_metadata,
    {
      startup-script = var.startup_script
      # Only instance-level SSH keys are honored; project-wide keys are ignored.
      block-project-ssh-keys = "true"
    }
  )

  # Shielded VM: secure boot + vTPM + integrity monitoring.
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  # Don't rebuild the VM just because the image moved or the startup script
  # changed — those are first-boot-only. Roll new container images in-VM with
  # `docker compose pull && docker compose up -d` instead.
  lifecycle {
    ignore_changes = [boot_disk[0].initialize_params[0].image, metadata["startup-script"]]
  }
}
