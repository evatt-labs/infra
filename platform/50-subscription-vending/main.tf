# Subscription vending
#
# Create MCA subscriptions through the approved invoice section and place them
# only into allow-listed destination management groups.
#
# PIPELINE IDENTITY: spn-subvending-prod-001. Separate its MCA billing role from
# its custom Azure subscription-placement role. It must not create management
# groups, policy definitions, workload resources, or arbitrary RBAC assignments.
#
# STATE: subscription-vending/vending.tfstate

