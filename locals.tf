locals {
  # Evatt Labs GCP organization
  org_id              = "493326646328"
  org_domain          = "evattlabs.com"
  workspace_customer  = "C03gqyb4m"

  # Sole billing account on the org (Evatt Labs). Used for any project
  # that opts into billing - the projects without a billing_account
  # declared below stay unbilled by design (e.g. kraai_local, gam).
  billing_account_id = "01E021-063CAA-9D7EB7"

  # Useful for module-level tagging if we add labels later
  common_labels = {
    managed_by = "terraform"
    repo       = "evatt-labs/evattlabs-infra"
  }
}
