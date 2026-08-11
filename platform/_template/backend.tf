# Backend declaration template
#
# Keep this block free of account-specific values. Pass resource group, storage
# account, container, and state key through a reviewed backend.hcl or pipeline
# arguments. Require Entra data-plane authentication; never use account keys/SAS.

terraform {
  backend "azurerm" {}
}

