# Evatt Labs Azure identity platform

This public reference implementation bootstraps and operates a standalone Azure
CAF-aligned tenant identity platform. It demonstrates secretless workload trust,
least-privilege control-plane identities, management-group and subscription
automation, policy as code, PIM-oriented human access, AKS workload identity,
and independently deployable Terraform roots.

Azure tenant and CAF landing-zone bootstrap guidance is documented in
[`docs/azure-bootstrap.md`](docs/azure-bootstrap.md). Run
`scripts/azure-discover.sh` before changing tenant bootstrap resources.

This repository retains the domain layer and is being extended with a standalone
Azure CAF identity-platform reference implementation:

- 🌐 **DNS** — migrate authoritative DNS for `evattlabs.com` from Cloudflare to
  Azure DNS while preserving Google Workspace and transactional-mail records
- 🔑 **Registrar** — retain domain registration outside Azure and manage only the
  nameserver delegation as a separate, tightly controlled root
- 🔐 **Azure identity platform** — management-group topology, federated pipeline
  identities, subscription vending, policy as code, PIM human access, Entra group
  administration, and AKS workload-identity examples

Google Workspace remains the production mail system for
`jordan@evattlabs.com`. Its MX, SPF, verification, and DKIM records are migration
invariants and must not be replaced by the stale Cloudflare Email Routing
configuration in `dns/email.tf`.

## Repository architecture

```text
infra/
├── bootstrap/       one-time trust-establishment contracts
├── scripts/         guarded discovery, elevation, bootstrap, and cleanup
├── config/          validated organizational intent
├── modules/         small reusable Terraform building blocks
├── platform/        tenant and shared-service control-plane roots
├── applications/    workload landing zones and workload identities
├── docs/            detailed security and migration records
└── .github/         secretless GitHub Actions workflows
```

Every directory below `platform/` or `applications/` is an independent
Terraform root with its own state key and least-privilege deployment identity.
Numeric platform prefixes express dependency order, not inherited permission.

## Trust model

GitHub Actions exchanges GitHub-issued OIDC tokens for short-lived Entra tokens.
No pipeline client secrets, certificates, storage keys, or SAS tokens are
created. Each federated identity credential matches one protected GitHub
environment exactly:

| Environment | Principals | Responsibility |
|---|---|---|
| `bootstrap` | `spn-mghierarchy-prod-001`, `spn-subvending-prod-001` | Management-group topology; MCA subscription creation and placement |
| `platform` | `spn-rbac-platform-prod-001`, `spn-entragroups-prod-001` | Platform-scope role assignments; Entra user lookup and group membership |
| `governance` | `spn-policy-prod-001` | Policy definitions, initiatives, assignments, and remediation |
| `applications` | `spn-rbac-landingzones-prod-001` | Landing-zone role assignments only |

The FIC subject format is
`repo:evatt-labs/infra:environment:<environment>`, the issuer is GitHub's token
service, and the only audience is `api://AzureADTokenExchange`.

The management-group hierarchy operator cannot place subscriptions. The
subscription-vending operator cannot create management groups or deploy
workloads. RBAC operators can manipulate role assignments but cannot deploy
resources. The Entra operator receives `User.Read.All` and
`GroupMember.ReadWrite.All`; it cannot mutate users, grant application consent,
or change group properties.

The platform and landing-zone RBAC principals are created during bootstrap but
receive no role assignment until their exact target management groups exist.
Assigning them at the organization parent would cause access to inherit across
both branches and violate the isolation model.

GitHub federation and AKS workload identity use the same Entra FIC mechanism but
different issuers and subjects. GitHub trusts an environment-scoped repository
subject. AKS trusts an exact Kubernetes service-account subject of the form
`system:serviceaccount:<namespace>:<service-account>` from the cluster's OIDC
issuer.

## Bootstrap

Prerequisites are Azure CLI, `jq`, Terraform or OpenTofu, an authenticated Global
Administrator who owns the bootstrap subscription, and sufficient MCA billing
authority to delegate Azure Subscription Creator at the selected invoice
section. Discover and review the tenant before writing anything:

```sh
./scripts/azure-discover.sh
az billing account list --output table
az billing profile list --account-name '<billing-account>' --output table
az billing invoice section list \
  --account-name '<billing-account>' \
  --profile-name '<billing-profile>' \
  --output table
```

MCA identifiers are runtime inputs because this repository is public. Supply
them locally for the one-time bootstrap; afterward store them as GitHub
`bootstrap` environment variables, not repository variables or file content:

```sh
export AZURE_BILLING_ACCOUNT_NAME='<billing-account>'
export AZURE_BILLING_PROFILE_NAME='<billing-profile>'
export AZURE_INVOICE_SECTION_NAME='<invoice-section>'
export GITHUB_REPOSITORY='evatt-labs/infra'
```

Use responsibility-specific client-ID variables because the `bootstrap` and
`platform` environments each authorize two different principals:

| GitHub environment | Configuration variables |
|---|---|
| `bootstrap` | `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_BILLING_ACCOUNT_NAME`, `AZURE_BILLING_PROFILE_NAME`, `AZURE_INVOICE_SECTION_NAME`, `MG_HIERARCHY_CLIENT_ID`, `SUBSCRIPTION_VENDING_CLIENT_ID` |
| `platform` | `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `PLATFORM_RBAC_CLIENT_ID`, `ENTRA_GROUPS_CLIENT_ID` |
| `governance` | `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `POLICY_CLIENT_ID` |
| `applications` | `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `LANDING_ZONE_RBAC_CLIENT_ID` |

These values identify trust endpoints but do not authenticate by themselves.
Do not add an Azure client secret. Environment protection rules and workflow job
permissions control which job may request the matching OIDC token. Each job maps
only its responsibility-specific value to `AZURE_CLIENT_ID` at runtime.

Run the one-time bootstrap inside a cleanup trap so temporary human elevation is
revoked even if initialization fails:

```sh
./scripts/pre-init.sh
trap './scripts/post-init.sh' EXIT
./scripts/init.sh
```

`pre-init.sh` self-elevates the signed-in Global Administrator to root User
Access Administrator and adds deterministic temporary management-group roles.
`init.sh` creates the organization management group, places the bootstrap
subscription, creates Azure Storage remote state, custom roles, app
registrations, service principals, exact FICs, Azure role assignments, Graph
application grants, and the MCA billing grant. `post-init.sh` deletes only the
known temporary assignments and removes root elevation.

The bootstrap output contains identifiers but no credentials. Treat it as an
ephemeral import aid; do not commit it. Import every bootstrapped object into
`platform/00-foundation/` before allowing Terraform to create adjacent tenant
resources.

## Publication gate

Before this repository becomes public, scan the complete Git object history and
working tree for credentials and sensitive identifiers. Rotate every credential
that ever entered a commit; deleting or rewriting it is not sufficient
revocation. Then create a reviewed orphan root commit, replace `main`, force-push
the intentionally rewritten branch, remove obsolete remote refs, and verify the
hosting service no longer exposes the old history. Existing forks and clones
cannot be recalled, so credential rotation remains mandatory.

## Deployment order

1. Import and validate `platform/00-foundation` with a no-op plan.
2. Create the CAF management-group topology under the Evatt Labs organization
   management group.
3. Assign the platform and landing-zone RBAC custom roles at their exact newly
   created management groups.
4. Vend Management, Connectivity, Security, workload, and sandbox subscriptions
   through the MCA invoice section and place each under its approved management
   group.
5. Deploy policy definitions and initiatives before assignments and remediation.
6. Deploy Security subscription services such as Log Analytics, Event Hubs, and
   Microsoft Sentinel as cost and demo scope permit.
7. Configure PIM-backed human access when Microsoft Entra ID Governance or P2 is
   licensed. Until then, do not misrepresent standing RBAC as PIM.
8. Deploy AKS and bind each workload identity to one namespace/service account
   and one narrowly scoped Azure authorization boundary.

## DNS and Google Workspace

Google Workspace remains the production mail system for
`jordan@evattlabs.com`. Moving authoritative DNS to Azure must preserve Google
MX, SPF, verification, and DKIM records as well as DMARC and active Resend/SES
records. Azure DNS does not provide domain registration or replace Cloudflare's
web proxy.

The migration separates ownership:

- `platform/20-shared-services/public-dns/` owns Azure DNS zones and records.
- `platform/20-shared-services/domain-registration/` owns external registrar
  delegation only.
- `applications/evattlabs-web/` owns hosting, edge, TLS, and custom-domain
  behavior.

The legacy `dns/` and `registrar/` roots remain rollback sources until the staged
cutover in [`docs/dns-migration.md`](docs/dns-migration.md) has passed direct
Azure nameserver, mail, web, DNSSEC, and propagation validation. Only then are
their Cloudflare/R2 resources, state, and credentials removed.

## Legacy domain layout

Each subdir is its own tofu root with its own state file in `evattlabs-tfstate` (R2):

```
evattlabs-infra/
├── dns/                  ← Cloudflare zone + records for evattlabs.com
│   ├── backend.hcl       ← key=dns/terraform.tfstate
│   ├── main.tf           ← zone + Resend records
│   ├── email.tf          ← Cloudflare Email Routing + apex SPF
│   ├── acme.tf           ← ACME challenge records
│   ├── verifications.tf  ← domain ownership TXT
│   └── ...
└── registrar/            ← Namecheap NS records → Cloudflare
    ├── backend.hcl       ← key=registrar/terraform.tfstate
    └── ...
```

These roots remain in place only until the staged migration described in
[`docs/dns-migration.md`](docs/dns-migration.md) is complete. Their state bucket
is `evattlabs-tfstate` (Cloudflare R2, S3-compatible).

## Workflow (per subdir)

```sh
cd dns
direnv allow                                   # loads sops secrets + AWS_PROFILE=r2
tofu init -backend-config=backend.hcl
tofu plan
```

## Auth model

- **R2 state backend** — `~/.aws/credentials [r2]` profile (`AWS_PROFILE=r2`, set by `.envrc`)
- **Secrets** — sops-encrypted `secrets/dev.enc.yaml`, decrypted via direnv with the
  helicon age key at `~/.config/sops/age/keys.txt`. Holds Cloudflare + Namecheap + Resend tokens.
- **Cloudflare provider** — reads `TF_VAR_cloudflare_api_token` (needs DNS:Edit, Zone:Read, Email Routing:Edit on evattlabs.com)
- **Namecheap provider** — reads `TF_VAR_namecheap_*`

Legacy domain roots currently run locally. Azure platform delivery will use
GitHub-hosted Actions with the environment-scoped OIDC trust described above.

## Azure platform layout

- `bootstrap/` and `scripts/` document the one-time human trust boundary.
- `modules/` contains small reusable Terraform building blocks.
- `platform/` contains independently deployed tenant control-plane roots.
- `applications/` contains workload landing-zone roots such as AKS.
- `config/` contains validated organizational intent.
- `.github/workflows/` will contain secretless GitHub OIDC pipelines.
- `docs/` contains the architecture, permission matrix, threat model, and demo
  runbook.

Start with `docs/identity-architecture.md`, `docs/permission-matrix.md`, and
`platform/README.md`. Terraform placeholders contain implementation contracts but
intentionally create no Azure resources.

## Critical rules

1. **Always** `tofu plan` and read the full diff before `tofu apply`.
2. R2 creds + age key are local-only — never committed.
3. Google Workspace mail records are production dependencies. Never apply the
   stale Cloudflare Email Routing resources in `dns/email.tf`.
4. Kraai product state lives in `~/Code/kraai-infra` against `kraai-tfstate` — not here.
