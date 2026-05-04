variable "cloudflare_api_token" {
  description = "Cloudflare account API token, scoped to: DNS:Edit on evattlabs.com zone, Zone:Read."
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID (from dash sidebar)."
  type        = string
}

variable "resend_dkim_value" {
  description = <<EOT
Resend's generated DKIM TXT value for evattlabs.com. Get from
console.resend.com → Domains → evattlabs.com → Records (the
`resend._domainkey` TXT row, "Content" column). Starts with
`p=MIGfMA0GCSqG...`. Public DNS data.
EOT
  type        = string
}

variable "resend_mail_from_subdomain" {
  description = "Subdomain Resend uses for MAIL FROM. Default 'send' matches Resend's standard."
  type        = string
  default     = "send"
}
