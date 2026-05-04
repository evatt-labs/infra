# registrar/

Namecheap NS-record management for both `evattlabs.com` and `kraai.dev`.

Delegates DNS to Cloudflare by setting the `nameservers` field on each
domain at Namecheap. Reads the actual Cloudflare-assigned nameservers via
remote state:

| Domain | Nameservers from |
|---|---|
| `evattlabs.com` | `evattlabs-tfstate/dns/terraform.tfstate` (this repo's `../dns/`) |
| `kraai.dev` | `kraai-tfstate/dns/terraform.tfstate` (`kraai-infra/terraform/dns/`) |

## Apply order matters

1. **First:** `tofu apply` in `../dns/` (creates evattlabs.com CF zone, outputs nameservers).
2. **First (parallel):** `tofu apply` in `kraai-infra/terraform/dns/` (kraai.dev zone, outputs).
3. **Then:** `tofu apply` here (reads both states' outputs, sets NS at Namecheap).

If you reorder these you'll see "remote state output not found" errors. Re-run after the upstream `tofu apply` lands.

## Apply

```fish
cd ~/Code/evattlabs-infra/registrar

# Verify Namecheap creds load
echo $TF_VAR_namecheap_user_name        # should print: jmevatt
echo $TF_VAR_namecheap_client_ip        # should print: your current public IP
test -n "$TF_VAR_namecheap_api_key" && echo "key present"

# Verify your IP is allowlisted at namecheap.com → Profile → Tools → API Access

tofu init -backend-config=backend.hcl
tofu plan
tofu apply
```

## When your IP changes

Namecheap requires the calling IP to be in the API allowlist. If your IP changes (new home network, new VPN exit, new CI runner):

1. Add the new IP at namecheap.com → Profile → Tools → API Access (allowlist takes a few minutes to propagate).
2. Update `TF_VAR_namecheap_client_ip` in `~/Code/evattlabs-infra/secrets/dev.enc.yaml`:
   ```fish
   sops ~/Code/evattlabs-infra/secrets/dev.enc.yaml
   ```
3. `direnv reload` in this dir.
4. Re-apply.

## Risk note

`mode = "OVERWRITE"` on `namecheap_domain_records` REPLACES all DNS settings at Namecheap. We use it because we're delegating to Cloudflare (only nameservers should be set at Namecheap; everything else lives in CF). If for some reason you have records at Namecheap that should be preserved, switch to `mode = "MERGE"` and only set the `nameservers` argument. But really, you shouldn't — Namecheap's DNS is unmanaged territory once you delegate.
