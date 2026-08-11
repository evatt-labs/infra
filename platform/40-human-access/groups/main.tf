# Human access: Entra security groups
#
# Create role-oriented groups such as platform owners, security administrators,
# policy administrators, and landing-zone owners. Manage user membership through
# the dedicated Graph principal, never through Azure RBAC pipeline identities.
#
# GRAPH: use User.Read.All + GroupMember.ReadWrite.All when groups already exist;
# use Group.ReadWrite.All only when this stack must manage group lifecycle.
#
# STATE: human-access/groups.tfstate

