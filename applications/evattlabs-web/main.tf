# Evatt Labs public website application root
#
# Owns the website hosting (Azure Static Web Apps, Free tier), its custom
# domains, and the deployment surface. Publishes only the DNS targets the
# public-dns root needs: the default hostname (www CNAME) and the resource ID
# (apex alias record).
#
# This root must not own the evattlabs.com DNS zone or registrar delegation.
#
# Custom-domain resources are added after TXT validation completes; see
# docs/dns-migration.md for the staged cutover.

locals {
  tags = {
    environment = "prod"
    managed-by  = "terraform"
    workload    = "evattlabs-web"
  }
}

resource "azurerm_resource_group" "web" {
  name     = "rg-evattlabsweb-prod-eus2-001"
  location = var.location
  tags     = local.tags
}

resource "azurerm_static_web_app" "site" {
  name                = "stapp-evattlabs-prod-eus2-001"
  resource_group_name = azurerm_resource_group.web.name
  location            = azurerm_resource_group.web.location

  sku_tier = "Free"
  sku_size = "Free"

  tags = local.tags
}
