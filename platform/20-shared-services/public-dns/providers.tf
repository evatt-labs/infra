# Credentials come from the operator's Azure CLI login during bootstrap and
# from GitHub OIDC environment variables in pipelines. Never Terraform inputs.

provider "azurerm" {
  features {}

  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id

  # The state storage account disables shared-key access; all data-plane
  # operations must authenticate with Entra ID.
  storage_use_azuread = true
}
