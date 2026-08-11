# Bootstrap boundary

Bootstrap is the only workflow allowed to rely on an interactive Global
Administrator. The current scripts live in `../scripts/`:

```sh
../scripts/azure-discover.sh
../scripts/pre-init.sh
../scripts/init.sh
../scripts/post-init.sh
```

`pre-init.sh` and `post-init.sh` bracket temporary human Azure-root access.
`init.sh` creates the organization management group, places the existing
bootstrap subscription beneath it, and creates the Azure Storage backend inside
that subscription. Azure resources cannot live directly in a management group.

Defaults follow the repository's CAF convention and can be overridden through
the `AZURE_ORGANIZATION_MG_*` and `AZURE_STATE_*` environment variables. The
script disables blob public access and shared-key authentication; pipelines must
use Microsoft Entra authentication for state access.

After creation, generate Terraform import blocks and adopt all durable objects in
`platform/00-foundation/pipeline-identities`. Bootstrap must never remain a second
owner of steady-state configuration.
