# Foundation: pipeline identities
#
# Own the app registrations, service principals, GitHub OIDC FICs, and narrowly
# scoped role assignments initially created by bootstrap/scripts/init.sh.
#
# FIRST APPLY: generate import blocks from bootstrap output before planning. This
# stack must adopt existing objects rather than create duplicates.
#
# STATE: foundation/pipeline-identities.tfstate
# PIPELINE: one bootstrap-only identity; remove its temporary grants after import.

