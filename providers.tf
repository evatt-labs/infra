# Authentication: Application Default Credentials.
# Run once on this machine:
#   gcloud auth application-default login
#
# Both providers share the same ADC; google-beta is needed for some org
# policies that haven't been GA'd into the stable provider yet.

provider "google" {
  # Most resources are org-scoped; per-resource project = X overrides where needed.
  user_project_override = true
}

provider "google-beta" {
  user_project_override = true
}
