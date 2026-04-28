locals {
  # Evatt Labs GCP organization
  org_id              = "493326646328"
  org_domain          = "evattlabs.com"
  workspace_customer  = "C03gqyb4m"

  # Default billing account — replace once known
  # Find with: gcloud billing accounts list
  billing_account_id = null # e.g. "01234A-56789B-CDEF12"

  # Useful for module-level tagging if we add labels later
  common_labels = {
    managed_by = "terraform"
    repo       = "evatt-labs/evattlabs-infra"
  }
}
