variable "cloudflare_api_token" {
  description = "Cloudflare account API token, scoped to: DNS:Edit on evattlabs.com zone, Zone:Read."
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID (from dash sidebar). Required for cloudflare_zone resource creation."
  type        = string
}
