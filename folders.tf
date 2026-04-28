# Folder hierarchy for the evattlabs.com organization.
#
# Why folders:
#   - IAM cascades from folder -> project, so we grant once at the folder
#     instead of N times per project.
#   - Org policies can be overridden per-folder (e.g. allow SA-key-upload
#     on /admin only, while keeping it locked org-wide).
#   - Billing reports group naturally by folder (production vs sandbox).
#
# We do NOT touch the existing `gcp-internal-cloud-setup` folder (Google
# auto-created it when Jordan went through the Cloud Setup wizard) — it is
# orthogonal to our hierarchy and can be left alone or deleted later.

resource "google_folder" "production" {
  display_name = "production"
  parent       = "organizations/${local.org_id}"
}

resource "google_folder" "development" {
  display_name = "development"
  parent       = "organizations/${local.org_id}"
}

resource "google_folder" "admin" {
  display_name = "admin"
  parent       = "organizations/${local.org_id}"
}

resource "google_folder" "sandbox" {
  display_name = "sandbox"
  parent       = "organizations/${local.org_id}"
}
