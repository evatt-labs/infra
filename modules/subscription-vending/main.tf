# MCA subscription-vending module
#
# PURPOSE: Create an MCA subscription and associate it with an approved landing-
# zone management group.
#
# AUTHORIZATION: Billing-scope permission creates the subscription; Azure RBAC at
# the destination management group authorizes placement. Treat these as separate
# controls and inputs.
#
# IMPLEMENT: alias/subscription creation, deterministic display name, workload
# metadata, management-group association, budget, and initial ownership outputs.
# Do not deploy workload resources from this module.

