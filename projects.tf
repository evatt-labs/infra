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
  name       = "Kraai"
  project_id = "kraai-492310"
  folder_id  = google_folder.production.id
  # billing_account intentionally omitted until known; managed in console for now.

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

# GAM project — holds the SA key for Workspace admin via GAM7.
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

# ──────────────────────────────────────────────────────────────────
# sandbox folder
# ──────────────────────────────────────────────────────────────────

# Auto-created when Jordan first used Gemini API / AI Studio. Probably
# unused; leave it parked here until decided.
resource "google_project" "gemini_default" {
  name       = "Default Gemini Project"
  project_id = "gen-lang-client-0159866751"
  folder_id  = google_folder.sandbox.id
}

# Auto-created on org sign-up (early 2026). Probably empty. Audit before
# deleting.
resource "google_project" "evattlabs_old" {
  name       = "Evatt Labs"
  project_id = "resolute-world-485311-b8"
  folder_id  = google_folder.sandbox.id
}
