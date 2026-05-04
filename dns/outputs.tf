# Nameservers consumed by ../registrar/ via remote state data source.
output "evattlabs_com_zone_id" {
  description = "Cloudflare zone ID for evattlabs.com"
  value       = cloudflare_zone.evattlabs_com.id
}

output "evattlabs_com_name_servers" {
  description = "Cloudflare-assigned nameservers for evattlabs.com (set these at the registrar)"
  value       = cloudflare_zone.evattlabs_com.name_servers
}
