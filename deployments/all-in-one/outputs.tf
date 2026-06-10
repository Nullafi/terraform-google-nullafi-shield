output "public_ip" {
  description = "Static external IP."
  value       = module.nullafi_shield.public_ip
}

output "shield_web_ui_url" {
  description = "Shield Web UI URL."
  value       = module.nullafi_shield.shield_web_ui_url
}

output "dns_instructions" {
  description = "DNS A record instructions."
  value       = module.nullafi_shield.dns_instructions
}

output "squid_proxy_endpoint" {
  description = "Squid proxy endpoint."
  value       = module.nullafi_shield.squid_proxy_endpoint
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = module.nullafi_shield.ssh_command
}

output "instance_name" {
  description = "Compute Engine instance name."
  value       = module.nullafi_shield.instance_name
}

output "vpc_name" {
  description = "VPC network name."
  value       = module.nullafi_shield.vpc_name
}

output "service_account_email" {
  description = "Email of the VM's service account."
  value       = module.nullafi_shield.service_account_email
}
