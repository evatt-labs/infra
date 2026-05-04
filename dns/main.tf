# ============================================================================
# evattlabs.com — Cloudflare zone + DNS records (Resend email setup).
# ============================================================================
#
# If the evattlabs.com zone DOES NOT exist in Cloudflare yet:
#   tofu apply creates it. Then point Namecheap NS at the zone's assigned
#   nameservers (handled by ../registrar/).
#
# If the evattlabs.com zone DOES exist already:
#   Delete old records via dashboard first (brief outage), then:
#   tofu init && tofu import cloudflare_zone.evattlabs_com <zone-id>
#   tofu plan && tofu apply

resource "cloudflare_zone" "evattlabs_com" {
  account_id = var.cloudflare_account_id
  zone       = "evattlabs.com"
  plan       = "free"
  type       = "full"

  lifecycle {
    ignore_changes = [plan]
  }
}

# ============================================================================
# Resend domain verification — DKIM
# ============================================================================
resource "cloudflare_record" "resend_dkim" {
  zone_id = cloudflare_zone.evattlabs_com.id
  name    = "resend._domainkey"
  type    = "TXT"
  content = var.resend_dkim_value
  ttl     = 1
  comment = "Resend DKIM (managed by evattlabs-infra/dns)"
}

# ============================================================================
# Resend MAIL FROM subdomain — MX + SPF
# ============================================================================
resource "cloudflare_record" "resend_mail_from_mx" {
  zone_id  = cloudflare_zone.evattlabs_com.id
  name     = var.resend_mail_from_subdomain
  type     = "MX"
  content  = "feedback-smtp.us-east-1.amazonses.com"
  priority = 10
  ttl      = 1
  comment  = "Resend MAIL FROM bounce/complaint endpoint (managed by evattlabs-infra/dns)"
}

resource "cloudflare_record" "resend_mail_from_spf" {
  zone_id = cloudflare_zone.evattlabs_com.id
  name    = var.resend_mail_from_subdomain
  type    = "TXT"
  content = "v=spf1 include:amazonses.com ~all"
  ttl     = 1
  comment = "Resend MAIL FROM SPF (managed by evattlabs-infra/dns)"
}

# ============================================================================
# DMARC monitoring policy
# ============================================================================
resource "cloudflare_record" "dmarc" {
  zone_id = cloudflare_zone.evattlabs_com.id
  name    = "_dmarc"
  type    = "TXT"
  content = "v=DMARC1; p=none; rua=mailto:dmarc@evattlabs.com"
  ttl     = 1
  comment = "DMARC monitoring policy — pre-enforcement (managed by evattlabs-infra/dns)"
}
