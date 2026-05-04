# evattlabs-infra

Company-level infrastructure-as-code for Evatt Labs.

This repo manages the **shared platform layer** that products live on top of:

- 🏢 **GCP organization** — `evattlabs.com` (org ID `493326646328`, customer ID `C03gqyb4m`)
- 📁 **Folders** — production / development / admin / sandbox
- 🚧 **Projects** — including the verified `kraai-492310` OAuth project
- 🔐 **Org policies** — the boring-but-load-bearing security baseline
- 👥 **Workspace** — users, groups, OUs (eventually, via `googleworkspace` provider)
- 🌐 **DNS for company-level domains** — `evattlabs.com` and `kraai.dev` zones, records, registrar NS bindings
- 🔑 **Namecheap registrar** — domain ownership + NS records pointing at Cloudflare

This repo does NOT manage:

| Lives in | What |
|---|---|
| `~/Code/kraai-infra` (private) | Kraai product platform: per-env Cloud Run, Kraai-specific R2 buckets, Stripe products, etc. |
| `~/Code/kraai-{runtime,control,web,…}` | Per-service Kraai code |
| `~/Code/lab` (private) | Helicon + Trantor NixOS dotfiles |
| `~/Code/evattlabs` | Marketing site — `evattlabs.com` content |

## Layout

The repo is split by **vendor / concern**, each subdir its own tofu root with its own state file in `evattlabs-tfstate`:

```
evattlabs-infra/
├── README.md                  ← this file
├── .github/workflows/
│   ├── tofu-plan.yml          ← matrix over subdirs
│   └── tofu-apply.yml         ← matrix over subdirs
├── gcp/                       ← GCP org/folders/projects/IAM/policies/CI
│   ├── backend.tf             ← s3-compat (R2) backend block (partial)
│   ├── backend.hcl            ← bucket=evattlabs-tfstate, key=gcp/terraform.tfstate
│   ├── ci.tf                  ← WIF + tofu-cicd SA
│   ├── folders.tf             ← 4 folders
│   ├── iam.tf                 ← group ↔ role bindings
│   ├── locals.tf              ← org id, domain, etc.
│   ├── org.tf                 ← organization-level resources & policies
│   ├── projects.tf            ← project imports + new projects
│   ├── providers.tf           ← google, google-beta
│   └── versions.tf
├── dns/                       ← (planned) Cloudflare zones + DNS records for kraai.dev / evattlabs.com
│   ├── backend.hcl            ← key=dns/terraform.tfstate
│   └── ...
└── registrar/                 ← (planned) Namecheap NS records pointing at Cloudflare
    ├── backend.hcl            ← key=registrar/terraform.tfstate
    └── ...
```

The two existing tofu states under `kraai-tfstate/cloudflare/` and `kraai-tfstate/dns/` are scheduled for **nuke + recreate** in the new `dns/` and `registrar/` subdirs (no original `.tf` source survived). Brief DNS outage acceptable since `kraai.dev` is pre-launch.

State buckets:

| Bucket | Holds |
|---|---|
| `evattlabs-tfstate` | Org-foundational state — domains, DNS, GCP projects, registrar (this repo's outputs) |
| `kraai-tfstate` | Kraai product-specific state — per-env Cloud Run, Kraai R2 buckets, Stripe products, etc. (`kraai-infra` repo's outputs) |

## Bootstrap (per subdir)

```sh
# State backend (one-time, already done)
wrangler r2 bucket create evattlabs-tfstate
# Create R2 API token (S3-compat, scoped to evattlabs-tfstate); add to ~/.aws/credentials [r2]

# Per-subdir local init
cd gcp
gcloud auth application-default login   # for google provider creds
tofu init -backend-config=backend.hcl
tofu plan
```

## What's Terraformed (gcp/)

| Resource | Status |
|---|---|
| Org policies (11) | ✅ live |
| Folders (production/development/admin/sandbox) | ✅ live |
| Projects (`evattlabs-admin`, `kraai-prod`, `kraai-local`, `claude-mcp`, `gam`) | ✅ live |
| WIF pool + provider for `github` | ✅ live |
| `tofu-cicd` service account + IAM | ✅ live |
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

## Auth model

- **Local:** `gcloud auth application-default login` as Jordan (org admin) for the GCP provider.
  R2 backend uses `~/.aws/credentials [r2]` profile.
  Cloudflare provider (when `dns/` lands) reads `CLOUDFLARE_API_TOKEN` env var.
  Namecheap provider (when `registrar/` lands) reads `NAMECHEAP_*` env vars.
- **CI:** Workload Identity Federation → `tofu-cicd@evattlabs-admin.iam.gserviceaccount.com`. R2 creds via GHA secrets.

## Critical rules

1. **Never** delete `kraai-492310`. OAuth verification is per-project; deletion = re-verify (weeks).
2. **Never** change `kraai-492310`'s consent screen via Terraform. See above.
3. **Never** widen org policies that allow SA key uploads beyond `/admin` folder.
4. **Always** run `tofu plan` and read every line of the diff before `tofu apply`.
5. State backend creds (`r2` AWS profile) are local-only — never committed.
6. **Never** put Kraai product-specific state in this repo. Kraai's per-env Cloud Run / R2 / Stripe state lives in `~/Code/kraai-infra` against `kraai-tfstate` bucket.
