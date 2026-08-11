# Governance: policy remediation authorization and tasks
#
# Grant each policy-assignment identity only the roles declared by its definition,
# then create bounded remediation tasks. Keep this separate because it requires
# role-assignment authority that the policy publication identity should not have.
#
# STATE: governance/policy-remediation.tfstate

