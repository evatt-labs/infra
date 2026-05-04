# Cloudflare Pages — apex + www point at evattlabs.pages.dev.
# Both are proxied (CNAME flattening on apex; standard CNAME on www).

resource "cloudflare_record" "apex_pages" {
  zone_id = cloudflare_zone.evattlabs_com.id
  name    = "evattlabs.com"
  type    = "CNAME"
  content = "evattlabs.pages.dev"
  ttl     = 1
  proxied = true
}

resource "cloudflare_record" "www_pages" {
  zone_id = cloudflare_zone.evattlabs_com.id
  name    = "www"
  type    = "CNAME"
  content = "evattlabs.pages.dev"
  ttl     = 1
  proxied = true
}
