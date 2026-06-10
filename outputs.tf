output "public_ip" {
  description = "Static external IP attached to the VM (Shield Web UI on 80/443, Squid on proxy_port)."
  value       = module.address.address
}

output "shield_web_ui_url" {
  description = "Shield Web UI URL."
  value       = var.host_name != null ? "https://${var.host_name}/login" : "http://${module.address.address}/login"
}

output "dns_instructions" {
  description = "Create a DNS A record pointing to this IP before HTTPS will activate."
  value = local.manage_dns ? "A record auto-created: ${var.host_name} → ${module.address.address}" : (
    var.host_name != null ? "Create a DNS A record: ${var.host_name} → ${module.address.address}" : "No hostname set — HTTPS disabled. Set host_name to enable Let's Encrypt."
  )
}

output "squid_proxy_endpoint" {
  description = "Squid proxy endpoint (configure as HTTP proxy)."
  value       = "${module.address.address}:${var.proxy_port}"
}

output "ssh_command" {
  description = "SSH command (requires ssh_public_key set and allowed_ssh_cidrs to cover your IP)."
  value       = var.ssh_public_key != null ? "ssh ${var.ssh_user}@${module.address.address}" : "SSH disabled (no ssh_public_key set). Use: gcloud compute ssh ${var.name_prefix}-vm --zone ${var.zone}"
}

output "instance_name" {
  description = "Compute Engine instance name."
  value       = module.compute_instance.name
}

output "vpc_name" {
  description = "VPC network name."
  value       = module.network.network_name
}

output "service_account_email" {
  description = "Email of the VM's service account."
  value       = module.service_account.email
}
