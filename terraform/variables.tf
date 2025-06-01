variable "cloudflare_api_token" {
  description = "Cloudflare API token with permissions to manage tunnels and DNS"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Your Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "The zone ID for your domain in Cloudflare"
  type        = string
}

variable "tunnel_name" {
  description = "Name for the Cloudflare tunnel (must be unique)"
  type        = string
}

variable "domain" {
  description = "The domain name (e.g., example.com)"
  type        = string
}

variable "subdomain" {
  description = "Subdomain for the service (leave empty for root domain)"
  type        = string
  default     = ""
}

variable "service_port" {
  description = "The port your service runs on"
  type        = number
  default     = 8080
}

variable "auth_method" {
  description = "Authentication method: 'none', 'email', or 'service_token'"
  type        = string
  default     = "none"
  
  validation {
    condition     = contains(["none", "email", "service_token"], var.auth_method)
    error_message = "Auth method must be 'none', 'email', or 'service_token'"
  }
}

variable "auth_emails" {
  description = "List of email addresses allowed to access (when auth_method is 'email')"
  type        = list(string)
  default     = []
}

variable "session_duration" {
  description = "How long access sessions last (e.g., '24h', '7d')"
  type        = string
  default     = "24h"
}

variable "config_output_path" {
  description = "Path where tunnel config files will be written"
  type        = string
  default     = "../cloudflared"
}

variable "origin_request_config" {
  description = "Advanced origin request configuration"
  type        = map(any)
  default     = null
}