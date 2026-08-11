# Domain registration and delegation root
#
# Purpose:
# - Retain evattlabs.com at its current registrar.
# - Change only its authoritative nameserver delegation after the Azure DNS zone
#   has been fully staged and validated.
#
# Required design boundaries:
# - Azure DNS is not a registrar; registration remains with the external
#   registrar.
# - Keep this root, state, credentials, approvals, and pipeline identity separate
#   from routine DNS record management.
# - Consume reviewed Azure DNS nameservers through a stable output contract or
#   explicit pipeline input. Do not couple this root to local relative state.
# - Never use an OVERWRITE-style registrar operation until every effect on host
#   records and nameservers has been reviewed.
# - Do not manage kraai.dev here; that domain belongs to its owning repository.
# - A delegation apply must be a manually approved cutover with rollback values
#   recorded in advance.

