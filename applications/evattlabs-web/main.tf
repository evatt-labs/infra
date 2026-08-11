# Evatt Labs public website application root
#
# Purpose:
# - Own the website hosting, edge/TLS service, and application deployment.
# - Publish only the DNS targets required by the public-dns root.
#
# This root must not own the evattlabs.com DNS zone or registrar delegation.
# Before removing Cloudflare proxy/Pages records, choose and validate the Azure
# hosting target, custom-domain verification, managed certificate, apex-domain
# behavior, and rollback path.

