# Tenant: management-group hierarchy
#
# Model: Evatt Labs -> Platform/{Management,Connectivity,Security}, Landing
# Zones/{Online,Corp}, Sandboxes, and Decommissioned.
#
# PIPELINE IDENTITY: spn-mghierarchy-prod-001 using a topology-only custom role.
# This root must not place subscriptions, assign Azure Policy, or manage RBAC.
#
# STATE: tenant/management-groups.tfstate

