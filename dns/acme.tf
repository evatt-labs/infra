# Let's Encrypt ACME challenge records.
#
# These are usually ephemeral -- ACME clients create them at challenge time,
# the CA verifies, and the client deletes. Records persisting in DNS imply
# stale challenges OR an ACME flow that intentionally pre-stages them.
#
# All carry literal double-quote characters as part of TXT content.
#
# Subdomains `loki`, `minio`, `minio-console` reference services that no
# longer run at evattlabs.com; their _acme-challenge records should be
# torn out next time you sweep. Apex + www likely correspond to active
# wildcard / leaf cert provisioning -- verify before removing.

resource "cloudflare_record" "acme_challenge_apex_a" {
  zone_id = cloudflare_zone.evattlabs_com.id
  name    = "_acme-challenge"
  type    = "TXT"
  content = "\"fAOjEKINygSgFyAlXWozPTN4IQlMn4bfhExEV3UII-g\""
  ttl     = 1
}

resource "cloudflare_record" "acme_challenge_apex_b" {
  zone_id = cloudflare_zone.evattlabs_com.id
  name    = "_acme-challenge"
  type    = "TXT"
  content = "\"kOEaDbZjbIqIjdRIpw6k2L50_WQd3JLc_BgQmEO_two\""
  ttl     = 1
}

resource "cloudflare_record" "acme_challenge_www" {
  zone_id = cloudflare_zone.evattlabs_com.id
  name    = "_acme-challenge.www"
  type    = "TXT"
  content = "\"ztRwGXLnxNYIvMNgWJ1GHVPvl91Pc5O73O3YROT6xh4\""
  ttl     = 1
}

resource "cloudflare_record" "acme_challenge_loki" {
  zone_id = cloudflare_zone.evattlabs_com.id
  name    = "_acme-challenge.loki"
  type    = "TXT"
  content = "\"2pPZ1M2122BFPt1288a2hKEuyAp5iKpBnj3tSAf-8FU\""
  ttl     = 1
}

resource "cloudflare_record" "acme_challenge_minio" {
  zone_id = cloudflare_zone.evattlabs_com.id
  name    = "_acme-challenge.minio"
  type    = "TXT"
  content = "\"vKMpsUdvR2zNmdICH1c4zhRzD2VVeZ59JvepBs6kaBc\""
  ttl     = 1
}

resource "cloudflare_record" "acme_challenge_minio_console" {
  zone_id = cloudflare_zone.evattlabs_com.id
  name    = "_acme-challenge.minio-console"
  type    = "TXT"
  content = "\"tyr1hxbXxjfkEPtRKWkylEaMAASGPYniUkdoZzjE3os\""
  ttl     = 1
}
