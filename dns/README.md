# dns/

Cloudflare zone + DNS records for `evattlabs.com`.

`kraai.dev` records live in a separate repo: `kraai-infra/terraform/dns/`.
NS records at Namecheap (for both domains) live in this repo's `../registrar/`.

## Records

| Name | Type | Content | Why |
|---|---|---|---|
| `evattlabs.com` | MX (10) | `feedback-smtp.us-east-1.amazonses.com` | AWS SES bounce/complaint endpoint |
| `evattlabs.com` | TXT | `v=spf1 include:amazonses.com ~all` | SPF — authorizes SES to send |
| `_dmarc.evattlabs.com` | TXT | `v=DMARC1; p=none; rua=mailto:dmarc@evattlabs.com` | DMARC monitoring (no enforcement v0) |

DKIM CNAMEs are added separately when SES verifies the domain. They'd be a
follow-up PR with the actual generated DKIM CNAME records as resources.

## Apply

```fish
cd ~/Code/evattlabs-infra/dns
tofu init -backend-config=backend.hcl
tofu plan
tofu apply
```

## If `evattlabs.com` zone already exists in Cloudflare

`tofu apply` will fail with "zone already exists." Import first:

```fish
# Get the zone ID from Cloudflare dash → Overview
tofu import cloudflare_zone.evattlabs_com <zone-id>
tofu plan      # should now show only DNS records to create, not zone
tofu apply
```

After apply, NS records returned by CF (output `evattlabs_com_name_servers`)
flow into `../registrar/` via remote state to set NS at Namecheap.
