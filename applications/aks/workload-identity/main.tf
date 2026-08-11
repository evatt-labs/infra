# Application: AKS workload-identity reference
#
# Demonstrate Kubernetes service-account OIDC federation to user-assigned managed
# identities. This stack can initially remain plan/test-only to avoid AKS compute
# cost, then target a short-lived integration cluster when required.
#
# Keep cluster infrastructure, workload identities, and application deployment in
# separate states and permission boundaries when implementation begins.
#
# STATE: workload-identity/aks.tfstate
