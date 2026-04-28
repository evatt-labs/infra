# IAM bindings for the evattlabs.com organization.
#
# Wired in v2. The existing `gcp-*-admins` Workspace groups follow the
# Google "GCP best practice" group naming, so we'll bind them to their
# corresponding org/folder roles here when ready.
#
# Group inventory (from `gam print groups`):
#   - gcp-billing-admins
#   - gcp-developers
#   - gcp-devops
#   - gcp-hybrid-connectivity-admins
#   - gcp-logging-monitoring-admins
#   - gcp-logging-monitoring-viewers
#   - gcp-organization-admins
#   - gcp-vpc-network-admins
#   - (1 more — `gam print groups` returned 9 total)
#
# Reference: https://cloud.google.com/architecture/identity/best-practices-for-planning
#
# TODO: define bindings here as we use them. No empty maps; unused groups
# stay unbound until there's a real reason.
