# evattlabs-infra secrets

Sops-encrypted local-dev variables for tofu providers (Cloudflare, Namecheap).

GCP creds come from `gcloud auth application-default login` (separate path,
unrelated to this dir). R2 backend creds come from `~/.aws/credentials [r2]`.

## What lives here

| File | Purpose |
|---|---|
| `dev.example.yaml` | Template — committed |
| `dev.enc.yaml` | Real values, sops-encrypted (committed encrypted) |

## Setup

```fish
cd ~/Code/evattlabs-infra/secrets
cp dev.example.yaml dev.enc.yaml
sops --encrypt --in-place dev.enc.yaml
sops dev.enc.yaml        # populate TF_VAR_* values
git add dev.enc.yaml
git commit -s -m "feat(secrets): populate dev"
```

## Rotating a value

```fish
sops dev.enc.yaml        # edit
git commit -am "chore(secrets): rotate <key>"
git push
# In any evattlabs-infra subdir terminal:
direnv reload            # picks up new value
```

## Re-keying

If you change which age public keys can decrypt (edit `../.sops.yaml`):

```fish
sops updatekeys dev.enc.yaml
```

## Hard rules (per ADR-0015 in kraai-protocol)

- Production credentials (the GCP-prod equivalents, etc.) are NEVER stored here.
  They live in GCP Secret Manager and are fetched by Workload Identity at runtime.
  This file holds only the things needed for `tofu apply` against Cloudflare and Namecheap.
- Namecheap requires IP allowlisting; if your IP changes, update `TF_VAR_namecheap_client_ip`
  in this file AND in the allowlist on namecheap.com Profile → API Access.
