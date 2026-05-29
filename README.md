# evattlabs-infra

Company-level infrastructure-as-code for Evatt Labs.

After the GCP/Workspace decommission (2026-05-29), this repo manages just the
domain layer:

- 🌐 **DNS** — `evattlabs.com` Cloudflare zone: records, ACME, Resend email, Cloudflare Email Routing
- 🔑 **Registrar** — Namecheap domain ownership + NS records pointing at Cloudflare

GCP org, folders, projects, Workspace, and WIF are **gone** — torn down to drop
the Workspace license cost. Email now flows through Cloudflare Email Routing to
a personal Gmail. The domain itself (Namecheap + Cloudflare) is unaffected.

## Layout

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

State bucket: `evattlabs-tfstate` (Cloudflare R2, S3-compat).

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

CI was removed in the decommission — it relied on GCP Workload Identity Federation
(now dead) and a self-hosted runner (gone). Run tofu locally. Re-add GitHub-hosted
CI later if desired.

## Critical rules

1. **Always** `tofu plan` and read the full diff before `tofu apply`.
2. R2 creds + age key are local-only — never committed.
3. The Cloudflare Email Routing rule update path is buggy (`required rule id missing`) —
   `jordan_forward` has `ignore_changes = [name]`. Don't remove it.
4. Kraai product state lives in `~/Code/kraai-infra` against `kraai-tfstate` — not here.
