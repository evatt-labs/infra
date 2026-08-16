# Root output contract: DNS targets consumed by the public-dns root.

output "default_host_name" {
  description = "SWA default hostname; target of the www CNAME."
  value       = azurerm_static_web_app.site.default_host_name
}

output "static_web_app_id" {
  description = "SWA resource ID; target of the apex alias A record."
  value       = azurerm_static_web_app.site.id
}

output "resource_group_name" {
  value = azurerm_resource_group.web.name
}
