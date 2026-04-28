# IAM bindings for the evattlabs.com organization.
#
# Pattern:
#   - Workspace groups bind to roles. User membership is managed in
#     Workspace via GAM, never via direct user bindings here.
#   - All bindings are `_iam_member` (additive). Never use `_iam_binding`
#     or `_iam_policy` at the org level - those are authoritative and
#     would clobber Jordan's owner binding on first apply.
#
# Group -> role mapping follows Google's "best practices for planning
# accounts and organizations":
#   https://cloud.google.com/architecture/identity/best-practices-for-planning
#
# Notes on what's NOT here yet:
#   - gcp-developers / gcp-devops are project-level groups; bindings get
#     authored per-project as workloads land. No org-wide grant.
#   - Per-project IAM (e.g. on kraai_prod) belongs in a future file
#     iam_projects.tf, not here.

locals {
  # Group -> list of org-level roles.
  org_group_roles = {
    "gcp-organization-admins" = [
      "roles/resourcemanager.organizationAdmin",
      "roles/resourcemanager.folderAdmin",
      "roles/orgpolicy.policyAdmin",
    ]
    "gcp-vpc-network-admins" = [
      "roles/compute.xpnAdmin",
      "roles/compute.networkAdmin",
      "roles/compute.securityAdmin",
    ]
    "gcp-hybrid-connectivity-admins" = [
      "roles/compute.networkAdmin",
      "roles/compute.xpnAdmin",
    ]
    "gcp-security-admins" = [
      "roles/iam.securityAdmin",
      "roles/orgpolicy.policyAdmin",
    ]
    "gcp-logging-monitoring-admins" = [
      "roles/logging.admin",
      "roles/monitoring.admin",
    ]
    "gcp-logging-monitoring-viewers" = [
      "roles/logging.viewer",
      "roles/monitoring.viewer",
    ]
    "gcp-billing-admins" = [
      # billing.admin lives on the billing account, not the org. Org-level
      # binding here is the read-only "see project costs" surface.
      "roles/billing.viewer",
    ]
  }

  # Flatten {group: [role]} -> {unique_key: {group, role}} for for_each.
  org_group_role_pairs = merge([
    for group, roles in local.org_group_roles : {
      for role in roles : "${group}|${role}" => {
        group = group
        role  = role
      }
    }
  ]...)
}

# ──────────────────────────────────────────────────────────────────
# Org-level group bindings.
# ──────────────────────────────────────────────────────────────────

resource "google_organization_iam_member" "group_org_roles" {
  for_each = local.org_group_role_pairs

  org_id = local.org_id
  role   = each.value.role
  member = "group:${each.value.group}@${local.org_domain}"
}

# ──────────────────────────────────────────────────────────────────
# Billing account bindings (separate IAM surface from the org).
# ──────────────────────────────────────────────────────────────────

resource "google_billing_account_iam_member" "billing_admins" {
  billing_account_id = local.billing_account_id
  role               = "roles/billing.admin"
  member             = "group:gcp-billing-admins@${local.org_domain}"
}
