# Root output contract: consumed by the domain-registration root.

output "name_servers" {
  description = "Azure-assigned authoritative nameservers for evattlabs.com."
  value       = azurerm_dns_zone.evattlabs_com.name_servers
}

output "zone_id" {
  value = azurerm_dns_zone.evattlabs_com.id
}

output "resource_group_name" {
  value = azurerm_resource_group.dns.name
}
