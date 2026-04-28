# evattlabs-infra

Company-level infrastructure-as-code for Evatt Labs.

This repo manages the **shared platform layer** that products live on top of:

- 🏢 **GCP organization** — `evattlabs.com` (org ID `493326646328`, customer ID `C03gqyb4m`)
- 📁 **Folders** — production / development / admin / sandbox
- 🚧 **Projects** — including the verified `kraai-492310` OAuth project
- 🔐 **Org policies** — the boring-but-load-bearing security baseline
- 👥 **Workspace** — users, groups, OUs (eventually, via `googleworkspace` provider)
- 🌐 **DNS for the company-level domains** (TBD)

This repo does NOT manage:

| Lives in | What |
|---|---|
| `~/code/kraai` (private monorepo) | Kraai product infra (when prod stack lands again) |
| `~/homelab` (public) | Homelab — Trantor / Proxmox / cloudflared on the homelab side |
| `~/code/evattlabs` | Marketing site — `evattlabs.com` content |

## Bootstrap

```sh
# State backend
wrangler r2 bucket create evattlabs-tfstate
# Create R2 API token at dash.cloudflare.com (Object R/W, scoped to evattlabs-tfstate)
# Add to ~/.aws/credentials under [r2-evattlabs]

# Local init
cp backend.hcl.example backend.hcl   # fill in values
cp providers.auto.tfvars.example providers.auto.tfvars   # if needed
gcloud auth application-default login   # for google provider creds
tofu init -backend-config=backend.hcl
tofu plan
```

## What's Terraformed

| Resource | Status |
|---|---|
| Org policies | TBD |
| Folders (production/development/admin/sandbox) | TBD |
| Existing projects (imported) | TBD |
| New projects | n/a yet |
| IAM bindings on `gcp-*` groups | TBD |
| Workspace users/groups/OUs | not yet (v2) |

## What's NOT Terraformed (and why)

### OAuth consent screen for `kraai-492310`

**The verified OAuth consent screen content is managed by hand in the GCP console.**
Reasons: (a) the legacy `iap.oauth_brands` API is being shut down March 2026; (b) the
new API surface is incomplete and not Terraform-ready for verified apps; (c) any drift
that triggers re-review costs weeks of human-Google time. **Don't put this in TF.**

The verified state for `kraai-492310` (as of 2026-04-28):

```
App name:           Kraai
User support email: <FILL IN>
Developer contact:  <FILL IN>
App logo:           <FILL IN — URL or asset path>
Privacy policy URL: https://kraai.dev/privacy
Terms of service:   https://kraai.dev/terms
Authorized domains: kraai.dev
Verification:       VERIFIED 2026-04-28
Scopes (verified):
  <FILL IN — list each scope you submitted, especially sensitive/restricted ones>
```

**If you change any of these, expect re-review.** Update this README to match before
clicking save in the console.

### OAuth client IDs/secrets

Manage in the console for prod (`kraai-492310`). Client IDs and secrets in TF state
are a security smell, and verification is per-consent-screen anyway, so there's no
benefit. Dev/staging clients in `kraai-local` *may* eventually be TF'd if useful.

## Layout

```
evattlabs-infra/
├── README.md                  ← this file
├── backend.tf                 ← s3-compatible (R2) backend block
├── backend.hcl.example        ← copy to backend.hcl, then `tofu init`
├── providers.tf               ← google, google-beta
├── versions.tf                ← required_providers
├── org.tf                     ← organization-level resources & policies
├── folders.tf                 ← 4 folders
├── projects.tf                ← project imports + new project definitions
├── iam.tf                     ← group ↔ role bindings (later)
└── locals.tf                  ← shared values (org id, domain, etc.)
```

## Auth model

- Local: `gcloud auth application-default login` as Jordan (org admin)
- CI: not wired yet — apply from Helicon for now

## Critical rules

1. **Never** delete `kraai-492310`. OAuth verification is per-project; deletion = re-verify (weeks).
2. **Never** change `kraai-492310`'s consent screen via Terraform. See above.
3. **Never** widen org policies that allow SA key uploads beyond `/admin` folder.
4. **Always** run `tofu plan` and read every line of the diff before `tofu apply`.
5. State backend creds (`r2-evattlabs` AWS profile) are local-only — never committed.
