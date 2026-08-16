# Foundation: Terraform state
#
# Owns the resource group, storage account, container, RBAC, versioning, and
# recovery controls for AzureRM remote state. Created by scripts/init.sh and
# adopted here via import blocks — this root must never recreate them.
#
# CHICKEN/EGG: first apply runs on local state, then this root migrates into
# the container it manages with `tofu init -migrate-state`.
#
# STATE AFTER MIGRATION: foundation/terraform-state.tfstate

locals {
  resource_group_name  = "rg-tfstate-prod-eus2-001"
  storage_account_name = "sttfstateprodaf7954"
  container_name       = "tfstate"

  tags = {
    environment = "prod"
    managed-by  = "terraform"
    workload    = "terraform-state"
  }
}

import {
  to = azurerm_resource_group.state
  id = "/subscriptions/${var.subscription_id}/resourceGroups/${local.resource_group_name}"
}

import {
  to = azurerm_storage_account.state
  id = "/subscriptions/${var.subscription_id}/resourceGroups/${local.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${local.storage_account_name}"
}

import {
  to = azurerm_storage_container.state
  id = "/subscriptions/${var.subscription_id}/resourceGroups/${local.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${local.storage_account_name}/blobServices/default/containers/${local.container_name}"
}

resource "azurerm_resource_group" "state" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "state" {
  name                = local.storage_account_name
  resource_group_name = azurerm_resource_group.state.name
  location            = azurerm_resource_group.state.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  tags = local.tags
}

# Managed through the ARM control plane (storage_account_id) so container
# lifecycle needs no data-plane role; blob reads/writes still require Entra
# data-plane RBAC.
resource "azurerm_storage_container" "state" {
  name                  = local.container_name
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "state_operators" {
  for_each = var.state_operator_object_ids

  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
  principal_type       = "User"
}
