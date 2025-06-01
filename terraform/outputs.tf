output "tunnel_id" {
  description = "The ID of the created tunnel"
  value       = cloudflare_tunnel.main.id
}

output "tunnel_url" {
  description = "The public URL for accessing your service"
  value       = "https://${local.full_domain}"
}

output "tunnel_cname" {
  description = "The CNAME target for the tunnel"
  value       = "${cloudflare_tunnel.main.id}.cfargotunnel.com"
}

output "service_token_id" {
  description = "The service token ID (if using service_token auth)"
  value       = var.auth_method == "service_token" ? cloudflare_access_service_token.main[0].id : null
  sensitive   = true
}

output "service_token_secret" {
  description = "The service token secret (if using service_token auth)"
  value       = var.auth_method == "service_token" ? cloudflare_access_service_token.main[0].client_secret : null
  sensitive   = true
}