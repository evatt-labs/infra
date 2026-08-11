# Management-group module
#
# PURPOSE: Create one management group and place it beneath an explicit parent.
#
# SECURITY BOUNDARY: This module manages topology only. It must not place
# subscriptions, assign policy, or create RBAC assignments.
#
# IMPLEMENT: immutable management-group ID, editable display name, parent ID,
# dependency-safe creation, and import documentation.

