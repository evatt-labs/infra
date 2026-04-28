# CI/CD via GitHub Actions + Workload Identity Federation.
#
# Pattern:
#   GHA OIDC token -> WIF pool/provider in evattlabs-admin -> impersonate
#   tofu-cicd SA -> SA holds least-privilege org-level admin roles for
#   tofu plan/apply.
#
# Why WIF (vs SA keys): org policy iam.disableServiceAccountKeyCreation
# is enforced everywhere except /admin folder, and even there we don't
# WANT static keys. WIF is key-less and audited per token exchange.
#
# Why granular roles (vs roles/resourcemanager.organizationAdmin): that
# role can grant any IAM at the org including to itself, blast radius of
# a compromise is the whole org. The stack below covers what tofu needs
# to manage today: folders, projects, org policies, billing linkage,
# project IAM, API enablement.

# ──────────────────────────────────────────────────────────────────
# APIs needed for WIF + impersonation in evattlabs-admin.
# ──────────────────────────────────────────────────────────────────

resource "google_project_service" "evattlabs_admin_cicd_apis" {
  for_each = toset([
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ])
  project            = google_project.evattlabs_admin.project_id
  service            = each.value
  disable_on_destroy = false
}

# ──────────────────────────────────────────────────────────────────
# CI/CD service account.
# ──────────────────────────────────────────────────────────────────

resource "google_service_account" "tofu_cicd" {
  account_id   = "tofu-cicd"
  display_name = "Tofu CI/CD"
  description  = "Impersonated by GitHub Actions in evatt-labs/evattlabs-infra via WIF to plan and apply org-level tofu."
  project      = google_project.evattlabs_admin.project_id
  depends_on   = [google_project_service.evattlabs_admin_cicd_apis]
}

locals {
  tofu_cicd_org_roles = [
    "roles/resourcemanager.folderAdmin",
    "roles/orgpolicy.policyAdmin",
    "roles/resourcemanager.projectCreator",
    "roles/resourcemanager.projectIamAdmin",
    "roles/resourcemanager.projectMover",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/iam.organizationRoleAdmin",
    # Manage WIF pools/providers + service accounts the CI itself depends
    # on (chicken-and-egg: tofu can't plan ci.tf without read access to
    # the WIF resources that authenticate it). Cascades to all projects.
    "roles/iam.workloadIdentityPoolAdmin",
    "roles/iam.serviceAccountAdmin",
    # Read-only on org IAM for plan diffs against existing bindings.
    "roles/iam.securityReviewer",
  ]
}

resource "google_organization_iam_member" "tofu_cicd_org_roles" {
  for_each = toset(local.tofu_cicd_org_roles)

  org_id = local.org_id
  role   = each.value
  member = "serviceAccount:${google_service_account.tofu_cicd.email}"
}

# Billing user lets the SA link billing accounts to projects it creates.
# Not billing.admin - the SA never needs to manage the billing account
# itself, only consume it.
resource "google_billing_account_iam_member" "tofu_cicd_billing" {
  billing_account_id = local.billing_account_id
  role               = "roles/billing.user"
  member             = "serviceAccount:${google_service_account.tofu_cicd.email}"
}

# ──────────────────────────────────────────────────────────────────
# Workload Identity Federation: trust GitHub Actions OIDC tokens.
# ──────────────────────────────────────────────────────────────────

resource "google_iam_workload_identity_pool" "github" {
  project                   = google_project.evattlabs_admin.project_id
  workload_identity_pool_id = "github-actions"
  display_name              = "GitHub Actions"
  description               = "OIDC tokens from token.actions.githubusercontent.com"
  depends_on                = [google_project_service.evattlabs_admin_cicd_apis]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = google_project.evattlabs_admin.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub OIDC"

  oidc {
    # No allowed_audiences: default audience is the WIF provider URI,
    # which is what google-github-actions/auth@v2 sends out of the box.
    # Pinning a custom audience requires audience: ... on the action input
    # too, and the attribute_condition below already restricts which repos
    # can use this provider.
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
    "attribute.actor"      = "assertion.actor"
  }

  # Belt-and-suspenders: only tokens minted by repos in this org can
  # use this provider, even if SA bindings ever drift.
  attribute_condition = "assertion.repository_owner == 'evatt-labs'"
}

# Allow the evattlabs-infra repo specifically (not the whole org) to
# impersonate the SA. Other repos in the org would need their own bindings.
resource "google_service_account_iam_member" "tofu_cicd_wif_impersonation" {
  service_account_id = google_service_account.tofu_cicd.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/evatt-labs/evattlabs-infra"
}

# ──────────────────────────────────────────────────────────────────
# Outputs - bake into workflow YAML.
# ──────────────────────────────────────────────────────────────────

output "wif_provider" {
  description = "Full WIF provider resource name for google-github-actions/auth@v2."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "tofu_cicd_sa_email" {
  description = "Service account impersonated by GHA via WIF."
  value       = google_service_account.tofu_cicd.email
}
