# Google Workspace receive (apex MX) + apex SPF.
# Resend MAIL FROM (send.evattlabs.com MX/TXT) lives in main.tf alongside
# the Resend DKIM and DMARC; this file is the apex/Google Workspace half.

resource "cloudflare_record" "google_mx_primary" {
  zone_id  = cloudflare_zone.evattlabs_com.id
  name     = "evattlabs.com"
  type     = "MX"
  content  = "aspmx.l.google.com"
  priority = 1
  ttl      = 3600
}

resource "cloudflare_record" "google_mx_alt1" {
  zone_id  = cloudflare_zone.evattlabs_com.id
  name     = "evattlabs.com"
  type     = "MX"
  content  = "alt1.aspmx.l.google.com"
  priority = 5
  ttl      = 3600
}

resource "cloudflare_record" "google_mx_alt2" {
  zone_id  = cloudflare_zone.evattlabs_com.id
  name     = "evattlabs.com"
  type     = "MX"
  content  = "alt2.aspmx.l.google.com"
  priority = 5
  ttl      = 3600
}

resource "cloudflare_record" "google_mx_alt3" {
  zone_id  = cloudflare_zone.evattlabs_com.id
  name     = "evattlabs.com"
  type     = "MX"
  content  = "alt3.aspmx.l.google.com"
  priority = 10
  ttl      = 3600
}

resource "cloudflare_record" "google_mx_alt4" {
  zone_id  = cloudflare_zone.evattlabs_com.id
  name     = "evattlabs.com"
  type     = "MX"
  content  = "alt4.aspmx.l.google.com"
  priority = 10
  ttl      = 3600
}

# Apex SPF -- authorizes Google Workspace as the apex sender. Soft-fail
# (~all) at apex on purpose; the strict -all is on the Resend MAIL FROM
# subdomain only. Tutanota was previously included; removed 2026-05-04.
resource "cloudflare_record" "apex_spf" {
  zone_id = cloudflare_zone.evattlabs_com.id
  name    = "evattlabs.com"
  type    = "TXT"
  content = "v=spf1 include:_spf.google.com ~all"
  ttl     = 3600
}
