# Configuration as code

These files should contain declarative organizational intent consumed by stacks.
Add JSON Schema validation before pipelines accept changes. Configuration must
not contain object IDs that can be discovered from stable names, secrets, tokens,
or environment-specific credentials.

`dns-zones.yaml` describes zone ownership and migration invariants. DNS record
values belong in a separately validated record catalog once the live Cloudflare
zone has been exported and reconciled; do not infer mail records from the legacy
Terraform state.
