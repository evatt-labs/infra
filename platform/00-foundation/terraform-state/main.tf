# Foundation: Terraform state
#
# Own the resource group, storage account, blob containers, RBAC, diagnostics,
# versioning, and recovery controls for AzureRM state.
#
# CHICKEN/EGG: Begin with local state, create the backend, then migrate this root
# with `terraform init -migrate-state`. Never use storage keys or SAS tokens.
#
# STATE AFTER MIGRATION: foundation/terraform-state.tfstate

