# CAF naming wrapper
#
# PURPOSE: Centralize the repository's inputs to Azure/naming/azurerm. Keep this
# wrapper thin; do not copy the upstream module implementation.
#
# IMPLEMENT: stable organization/workload/environment/region/instance inputs,
# region abbreviations, required tags, and documented exceptions for Entra
# directory objects and management-group display names.
#
# OUTPUT: typed names consumed by root modules. Avoid random names for identities
# and resources that must be imported or referenced across state boundaries.

