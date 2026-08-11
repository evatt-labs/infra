# Governance: Azure Policy assignments
#
# Assign initiatives at the narrowest useful management-group scope. Consume the
# Security stack's Log Analytics and Event Hub destination IDs.
#
# Use system-assigned identities for DeployIfNotExists/Modify assignments. This
# root creates assignments but does not grant their remediation roles.
#
# STATE: governance/policy-assignments.tfstate

