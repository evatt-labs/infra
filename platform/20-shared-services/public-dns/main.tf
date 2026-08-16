# Azure public DNS root
#
# Owns the evattlabs.com DNS zone and record sets, materialized from the
# reviewed catalog in config/dns-records-evattlabs.yaml. Website records are
# derived from the evattlabs-web root's output contract. Registration and
# nameserver delegation belong to the separate domain-registration root.
#
# Google Workspace MX/SPF/verification/DKIM records are production invariants;
# the check block below fails the plan if the catalog loses them.

locals {
  catalog = yamldecode(file("${path.module}/../../../config/dns-records-evattlabs.yaml"))

  tags = {
    environment = "prod"
    managed-by  = "terraform"
    workload    = "public-dns"
  }
}

data "terraform_remote_state" "evattlabs_web" {
  backend = "azurerm"

  config = {
    resource_group_name  = "rg-tfstate-prod-eus2-001"
    storage_account_name = "sttfstateprodaf7954"
    container_name       = "tfstate"
    key                  = "applications/evattlabs-web.tfstate"
    use_azuread_auth     = true
    subscription_id      = var.subscription_id
  }
}

check "google_workspace_invariants" {
  assert {
    condition = contains(
      [for r in local.catalog.mx : r.name], "@"
      ) && contains(
      flatten([for r in local.catalog.mx : [for m in r.records : m.exchange] if r.name == "@"]),
      "aspmx.l.google.com"
    )
    error_message = "Catalog lost the Google Workspace apex MX records (production invariant)."
  }

  assert {
    condition = anytrue([
      for r in local.catalog.txt : r.name == "@" && anytrue([
        for v in r.values : startswith(v, "v=spf1 include:_spf.google.com")
      ])
    ])
    error_message = "Catalog lost the Google Workspace apex SPF record (production invariant)."
  }
}

resource "azurerm_resource_group" "dns" {
  name     = "rg-publicdns-prod-eus2-001"
  location = var.location
  tags     = local.tags
}

resource "azurerm_dns_zone" "evattlabs_com" {
  name                = "evattlabs.com"
  resource_group_name = azurerm_resource_group.dns.name
  tags                = local.tags
}

resource "azurerm_dns_mx_record" "catalog" {
  for_each = { for r in local.catalog.mx : r.name => r }

  name                = each.value.name
  zone_name           = azurerm_dns_zone.evattlabs_com.name
  resource_group_name = azurerm_resource_group.dns.name
  ttl                 = each.value.ttl

  dynamic "record" {
    for_each = each.value.records
    content {
      preference = record.value.preference
      exchange   = record.value.exchange
    }
  }
}

resource "azurerm_dns_txt_record" "catalog" {
  for_each = { for r in local.catalog.txt : r.name => r }

  name                = each.value.name
  zone_name           = azurerm_dns_zone.evattlabs_com.name
  resource_group_name = azurerm_resource_group.dns.name
  ttl                 = each.value.ttl

  dynamic "record" {
    for_each = each.value.values
    content {
      value = record.value
    }
  }
}

# Apex routes to the Static Web App via an alias record; Azure DNS resolves
# the SWA's current addresses, which have no stable literal IP.
resource "azurerm_dns_a_record" "apex_swa" {
  name                = "@"
  zone_name           = azurerm_dns_zone.evattlabs_com.name
  resource_group_name = azurerm_resource_group.dns.name
  ttl                 = 300
  target_resource_id  = data.terraform_remote_state.evattlabs_web.outputs.static_web_app_id
}

resource "azurerm_dns_cname_record" "www_swa" {
  name                = "www"
  zone_name           = azurerm_dns_zone.evattlabs_com.name
  resource_group_name = azurerm_resource_group.dns.name
  ttl                 = 300
  record              = data.terraform_remote_state.evattlabs_web.outputs.default_host_name
}
