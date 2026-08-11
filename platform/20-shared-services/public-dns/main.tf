# Azure public DNS root
#
# Purpose:
# - Create the Azure DNS public zone for evattlabs.com in the shared-services
#   subscription.
# - Materialize a reviewed record catalog after reconciling it against the live
#   Cloudflare zone.
# - Export Azure-assigned authoritative nameservers for the separate registrar
#   delegation root.
#
# Required design boundaries:
# - This root owns DNS zones and record sets, not the domain registration.
# - Google Workspace MX, SPF, verification, and DKIM records are production
#   invariants. Preserve them byte-for-byte unless a deliberate mail change has
#   been separately approved and validated.
# - Preserve Resend/SES MAIL FROM, DKIM, DMARC, ACME, and site-verification
#   records only after confirming each live record and its current owner.
# - Do not reproduce Cloudflare Email Routing resources or its SPF include.
# - Cloudflare-proxied web records require a deliberate hosting/edge migration;
#   Azure DNS is authoritative DNS and does not replace Cloudflare's proxy.
# - Use an Azure Storage backend key dedicated to this root.
#
# Suggested implementation:
# 1. Read a schema-validated DNS record catalog from config/.
# 2. Use the Azure CAF naming module for the resource group where applicable.
# 3. Create azurerm_dns_zone and typed record-set resources with for_each.
# 4. Add preconditions preventing omission of protected Google Workspace records.
# 5. Output name_servers, zone_id, and resource_group_name.

