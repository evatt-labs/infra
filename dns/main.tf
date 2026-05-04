# ============================================================================
# evattlabs.com — Cloudflare zone + DNS records
# ============================================================================
#
# If the evattlabs.com zone DOES NOT exist in Cloudflare yet:
#   tofu apply will create it. Then point Namecheap NS at the zone's
#   assigned nameservers (handled by ../registrar/).
#
# If the evattlabs.com zone DOES exist already:
#   `tofu import cloudflare_zone.evattlabs_com <zone-id>` first, then apply.
#
# Records below mirror the email-from-SES pattern at the apex.
# (SES sender lives elsewhere; these records exist so SES can send + bounce.)

resource "cloudflare_zone" "evattlabs_com" {
  account_id = var.cloudflare_account_id
  zone       = "evattlabs.com"
  plan       = "free"
  type       = "full"
}

# Apex MX → SES bounce-handling endpoint
resource "cloudflare_record" "apex_mx_ses" {
  zone_id  = cloudflare_zone.evattlabs_com.id
  name     = "evattlabs.com"
  type     = "MX"
  content  = "feedback-smtp.us-east-1.amazonses.com"
  priority = 10
  ttl      = 1 # auto
  comment  = "AWS SES bounce/complaint feedback (managed by evattlabs-infra/dns)"
}

# Apex SPF — authorize SES to send on behalf of evattlabs.com
resource "cloudflare_record" "apex_spf" {
  zone_id = cloudflare_zone.evattlabs_com.id
  name    = "evattlabs.com"
  type    = "TXT"
  content = "v=spf1 include:amazonses.com ~all"
  ttl     = 1
  comment = "SPF — authorizes amazonses.com (managed by evattlabs-infra/dns)"
}

# DMARC policy
resource "cloudflare_record" "dmarc" {
  zone_id = cloudflare_zone.evattlabs_com.id
  name    = "_dmarc.evattlabs.com"
  type    = "TXT"
  content = "v=DMARC1; p=none; rua=mailto:dmarc@evattlabs.com"
  ttl     = 1
  comment = "DMARC monitoring policy (managed by evattlabs-infra/dns)"
}
