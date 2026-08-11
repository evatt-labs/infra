# Human PIM assignment module
#
# PURPOSE: Create eligible, time-bound Azure resource role assignments for human
# groups. Workload identities are intentionally excluded because they cannot
# perform PIM activation.
#
# IMPLEMENT: principal group, scope, role definition, eligibility schedule, and
# justification. Activation policy settings belong in the appropriate PIM policy
# stack/API implementation.
#
# LICENSING: Requires Microsoft Entra ID P2 or Entra ID Governance for affected
# users. Keep the module disabled when the tenant has no qualifying SKU.

