# Domain ownership verifications -- third-party services.
#
# TXT content strings include literal double-quote characters as `\"...\"`
# to match the live record exactly and keep plan stable.

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
