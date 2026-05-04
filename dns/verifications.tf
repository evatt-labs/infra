# Domain ownership verifications -- third-party services.
#
# Both records have literal double-quote characters as part of their TXT
# content (legacy from how they were originally created). Tofu content
# strings include the quotes as `\"...\"` to match the live record exactly
# and keep plan stable.

# Google Search Console / Workspace domain verification.
resource "cloudflare_record" "google_site_verification" {
  zone_id = cloudflare_zone.evattlabs_com.id
  name    = "evattlabs.com"
  type    = "TXT"
  content = "\"google-site-verification=KZL9RB64aCgbVSAKhKdHKRXwlQpoVoEehgm6NmcypfE\""
  ttl     = 3600
}

# Opaque domain-verification challenge. Hostname is itself a 40-char hex
# (looks like a sha1) and the content is a different 40-char hex. Origin
# of this verification: unknown -- carry forward as-is until identified
# and either renewed or removed.
resource "cloudflare_record" "domain_verification_ad9d065f" {
  zone_id = cloudflare_zone.evattlabs_com.id
  name    = "ad9d065f3518ae5180a8f6183ed3b26b7fa5ac08"
  type    = "TXT"
  content = "\"7fa5ec45be692b4c96b55774ed497565ae43d54e\""
  ttl     = 60
}
