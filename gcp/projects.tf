# Existing projects, imported into Terraform state.
#
# IMPORT FLOW (do once, never again):
#   tofu init -backend-config=backend.hcl -reconfigure
#   tofu import google_project.kraai_prod      projects/kraai-492310
#   tofu import google_project.kraai_local     projects/kraai-local
#   tofu import google_project.gam             projects/gam-project-0i275
#   tofu import google_project.gemini_default  projects/gen-lang-client-0159866751
#   tofu import google_project.evattlabs_old   projects/resolute-world-485311-b8
#
# After import, `tofu plan` will show the diff between current GCP state
# and the desired state below. Adjust the resource definitions to match
# real state (especially `name` and `project_id`) so the plan is empty,
# THEN apply the folder moves intentionally.
#
# CRITICAL: do NOT change `project_id` on any of these. Project IDs are
# permanent. The verified OAuth client on `kraai-492310` is bound to that
# project ID forever.

# ──────────────────────────────────────────────────────────────────
# production folder
# ──────────────────────────────────────────────────────────────────

# The verified OAuth project. DO NOT DELETE OR RECREATE.
resource "google_project" "kraai_prod" {
  name            = "Kraai"
  project_id      = "kraai-492310"
  folder_id       = google_folder.production.id
  billing_account = local.billing_account_id

  lifecycle {
    prevent_destroy = true
  }
}

# ──────────────────────────────────────────────────────────────────
# development folder
# ──────────────────────────────────────────────────────────────────

resource "google_project" "kraai_local" {
  name       = "Kraai Local"
  project_id = "kraai-local"
  folder_id  = google_folder.development.id

  lifecycle {
    prevent_destroy = true
  }
}

# ──────────────────────────────────────────────────────────────────
# admin folder
# ──────────────────────────────────────────────────────────────────

# GAM project — holds the SA key for Workspace admin via GAM.
# Org policy `iam.disableServiceAccountKeyUpload` is enforced everywhere
# EXCEPT inside this folder (override defined in org.tf).
resource "google_project" "gam" {
  name       = "GAM Project"
  project_id = "gam-project-0i275"
  folder_id  = google_folder.admin.id

  lifecycle {
    prevent_destroy = true
  }
}

# Admin / management billing project. ADC quota project for tofu runs
# and any other org-level admin API calls. No application workloads
# should land here — keeps the billing surface clean.
resource "google_project" "evattlabs_admin" {
  name            = "Evatt Labs Admin"
  project_id      = "evattlabs-admin"
  folder_id       = google_folder.admin.id
  billing_account = local.billing_account_id

  lifecycle {
    prevent_destroy = true
  }
}

# ──────────────────────────────────────────────────────────────────
# sandbox folder
# ──────────────────────────────────────────────────────────────────

# Hosts the Claude Code MCP service accounts (Gmail/Calendar/Drive
# integrations via `claude-workspace@...`). Auto-created on org sign-up,
# previously named "Evatt Labs" - renamed to make the actual purpose
# obvious. Project ID is permanent and can't be changed.
resource "google_project" "claude_mcp" {
  name            = "Claude MCP Access"
  project_id      = "resolute-world-485311-b8"
  folder_id       = google_folder.sandbox.id
  billing_account = local.billing_account_id
}

# Renamed from `evattlabs_old` -> `claude_mcp` (2026-04-28). Keeps state
# in sync without a destroy/recreate.
moved {
  from = google_project.evattlabs_old
  to   = google_project.claude_mcp
}
