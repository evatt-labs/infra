# evattlabs.com DNS migration

## Decision

Keep `evattlabs.com` registered at its existing registrar, move authoritative DNS
hosting to Azure DNS, and keep Google Workspace as the production mail system for
`jordan@evattlabs.com`. The Entra custom domain is already verified; changing
authoritative DNS does not make the tenant more authoritative.

The legacy `dns/` and `registrar/` roots must remain untouched until cutover is
verified. Their eventual replacements are:

- `platform/20-shared-services/public-dns/` — Azure DNS zones and record sets.
- `platform/20-shared-services/domain-registration/` — external registrar and
  nameserver delegation only.
- `applications/evattlabs-web/` — website hosting, edge, TLS, and custom domain.

## Production invariants

At minimum, preserve and validate:

- Google Workspace MX records.
- Apex SPF authorizing Google Workspace.
- Google domain-verification TXT records.
- Google Workspace DKIM TXT records discovered in the live zone.
- DMARC policy.
- Resend/SES DKIM, MAIL FROM MX, and MAIL FROM SPF records that are still used.
- Any active ACME challenges and other ownership-verification records.

The repository's legacy `dns/email.tf` is not authoritative: it describes
Cloudflare Email Routing and a Cloudflare SPF include, while live DNS uses Google
Workspace. It must not be applied during migration.

## Staged cutover

1. Export the complete live Cloudflare zone and registrar settings. Record DNSSEC
   state, current nameservers, TTLs, and rollback values.
2. Reconcile the export against live authoritative queries and service consoles.
   Classify every record by owner and remove nothing merely because it looks old.
3. Choose the replacement for the Cloudflare-proxied website. Prove apex and
   `www` routing, TLS issuance, redirects, and rollback before DNS delegation.
4. Create the Azure DNS zone and all reviewed records without changing the
   registrar. Query each Azure authoritative nameserver directly and compare the
   answers with the approved catalog.
5. Lower relevant TTLs ahead of cutover where the current provider permits it.
   Handle DNSSEC explicitly; stale DS records can make the entire domain fail.
6. In a manually approved window, change registrar nameservers to the exact Azure
   DNS nameservers. Do not change MX or mail configuration during this step.
7. Monitor authoritative delegation, website behavior, certificate issuance,
   inbound and outbound Google Workspace mail, SPF/DKIM/DMARC results, and Resend.
8. After propagation and an agreed observation period, import/adopt the final
   resources into their new states. Only then remove the legacy Cloudflare/R2
   roots and credentials.

## State and identity boundaries

Public DNS and domain delegation use independent Azure Storage state keys and
independent least-privilege pipeline identities. Routine DNS automation receives
no registrar permission. Registrar automation receives no Azure resource-write
permission beyond what is required to read the approved nameserver contract.

