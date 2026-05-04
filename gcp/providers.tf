# Authentication: Application Default Credentials.
# Run once on this machine:
#   gcloud auth application-default login
#
# Both providers share the same ADC; google-beta is needed for some org
# policies that haven't been GA'd into the stable provider yet.

provider "google" {
  # Most resources are org-scoped; per-resource project = X overrides where needed.
  # billing_project is the project that gets billed for the API calls and
  # whose quotas they count against. Required when ADC is a user account.
  billing_project       = "evattlabs-admin"
  user_project_override = true
}

provider "google-beta" {
  billing_project       = "evattlabs-admin"
  user_project_override = true
}
