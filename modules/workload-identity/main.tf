# AKS workload-identity module
#
# PURPOSE: Bind one Kubernetes service-account subject to one user-assigned
# managed identity with an exact federated identity credential.
#
# TRUST: issuer = AKS OIDC issuer; subject = system:serviceaccount:<ns>:<name>;
# audience = api://AzureADTokenExchange.
#
# SECURITY BOUNDARY: One identity per workload/security boundary. Azure RBAC and
# Key Vault data-plane grants must be explicit inputs or separate resources.

