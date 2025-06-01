terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Provider configuration
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Generate a secret for the tunnel
resource "random_password" "tunnel_secret" {
  length  = 64
  special = false
}

# Create the tunnel
resource "cloudflare_tunnel" "main" {
  account_id = var.cloudflare_account_id
  name       = var.tunnel_name
  secret     = base64encode(random_password.tunnel_secret.result)
}

# Configure tunnel routing
resource "cloudflare_tunnel_config" "main" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_tunnel.main.id

  config {
    ingress_rule {
      hostname = local.full_domain
      service  = "http://localhost:${var.service_port}"
      
      dynamic "origin_request" {
        for_each = var.origin_request_config != null ? [var.origin_request_config] : []
        content {
          no_tls_verify     = lookup(origin_request.value, "no_tls_verify", null)
          connect_timeout   = lookup(origin_request.value, "connect_timeout", null)
          tcp_keep_alive    = lookup(origin_request.value, "tcp_keep_alive", null)
          keep_alive_timeout = lookup(origin_request.value, "keep_alive_timeout", null)
        }
      }
    }
    
    # Catch-all rule
    ingress_rule {
      service = "http_status:404"
    }
  }
}

# DNS record for the tunnel
resource "cloudflare_record" "tunnel_dns" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain != "" ? var.subdomain : "@"
  type    = "CNAME"
  value   = "${cloudflare_tunnel.main.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}

# Access configuration based on auth method
resource "cloudflare_access_application" "main" {
  count = var.auth_method != "none" ? 1 : 0
  
  zone_id                   = var.cloudflare_zone_id
  name                      = "${var.tunnel_name}-access"
  domain                    = local.full_domain
  type                      = "self_hosted"
  session_duration          = var.session_duration
  auto_redirect_to_identity = false
}

# Email-based access policy
resource "cloudflare_access_policy" "email_policy" {
  count = var.auth_method == "email" && length(var.auth_emails) > 0 ? 1 : 0
  
  zone_id        = var.cloudflare_zone_id
  application_id = cloudflare_access_application.main[0].id
  name           = "${var.tunnel_name}-email-policy"
  decision       = "allow"
  precedence     = 1

  include {
    email = var.auth_emails
  }
}

# Service token access policy
resource "cloudflare_access_service_token" "main" {
  count = var.auth_method == "service_token" ? 1 : 0
  
  zone_id = var.cloudflare_zone_id
  name    = "${var.tunnel_name}-service-token"
}

resource "cloudflare_access_policy" "service_token_policy" {
  count = var.auth_method == "service_token" ? 1 : 0
  
  zone_id        = var.cloudflare_zone_id
  application_id = cloudflare_access_application.main[0].id
  name           = "${var.tunnel_name}-service-token-policy"
  decision       = "non_identity"
  precedence     = 1

  include {
    service_token = [cloudflare_access_service_token.main[0].id]
  }
}

# Generate configuration files
resource "local_file" "tunnel_credentials" {
  content = jsonencode({
    AccountTag   = var.cloudflare_account_id
    TunnelID     = cloudflare_tunnel.main.id
    TunnelName   = var.tunnel_name
    TunnelSecret = base64encode(random_password.tunnel_secret.result)
  })
  
  filename        = "${var.config_output_path}/credentials.json"
  file_permission = "0600"
}

resource "local_file" "tunnel_config" {
  content = yamlencode({
    tunnel = cloudflare_tunnel.main.id
    credentials-file = "/home/nonroot/.cloudflared/credentials.json"
    metrics = "0.0.0.0:2000"
    no-autoupdate = true
  })
  
  filename        = "${var.config_output_path}/config.yml"
  file_permission = "0644"
}

# Local values
locals {
  full_domain = var.subdomain != "" ? "${var.subdomain}.${var.domain}" : var.domain
}