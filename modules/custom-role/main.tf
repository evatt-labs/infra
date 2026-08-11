# Custom Azure RBAC role module
#
# PURPOSE: Define narrowly scoped control-plane roles used where Azure built-in
# roles are broader than a pipeline responsibility.
#
# SECURITY BOUNDARY: Require explicit actions, notActions, and assignableScopes.
# Reject wildcard actions unless a documented architecture decision permits one.
#
# TEST: Prove allowed operations and important denied operations from the
# permission matrix.

