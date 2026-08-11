# Federated pipeline identity module
#
# PURPOSE: Create a single-tenant Entra application, service principal, and exact
# GitHub Actions federated identity credentials for one responsibility.
#
# SECURITY BOUNDARY: Accept explicit issuer, audience, repository, workflow, and
# environment claims. Never create a password/client secret. Keep flexible FICs
# in a separate opt-in path because that capability is preview.
#
# DO NOT: Assign broad Azure RBAC or Microsoft Graph permissions inside this
# module. Bind privileges in the owning stack so scope remains reviewable.

