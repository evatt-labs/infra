# Cloudflare Email Routing + apex SPF.
# Forwards jordan@evattlabs.com → jmevatt@gmail.com.
# Resend MAIL FROM (send.evattlabs.com MX/TXT) lives in main.tf.
#
# Note: Cloudflare manages its own MX records when Email Routing is enabled —
# do not declare cloudflare_record MX resources here, CF owns them.

resource "cloudflare_email_routing_settings" "evattlabs_com" {
  zone_id = cloudflare_zone.evattlabs_com.id
  enabled = true
}

resource "cloudflare_email_routing_rule" "jordan_forward" {
  zone_id = cloudflare_zone.evattlabs_com.id
  name    = "jordan-forward"
  enabled = true

  matcher {
    type  = "literal"
    field = "to"
    value = "jordan@evattlabs.com"
  }

  action {
    type  = "forward"
    value = ["jmevatt@gmail.com"]
  }

  # The provider's email-routing-rule update path is buggy ("required rule id
  # missing") — the rule forwards correctly, so ignore the cosmetic name drift.
  lifecycle {
    ignore_changes = [name]
  }
}

# Apex SPF — authorizes Cloudflare Email Routing. Soft-fail (~all) on
# purpose; strict -all lives on the Resend MAIL FROM subdomain only.
resource "cloudflare_record" "apex_spf" {
  zone_id = cloudflare_zone.evattlabs_com.id
  name    = "evattlabs.com"
  type    = "TXT"
  content = "v=spf1 include:_spf.mx.cloudflare.net ~all"
  ttl     = 3600
}
