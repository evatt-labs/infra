# Namecheap requires:
#   1. API access enabled at namecheap.com → Profile → Tools → API Access.
#   2. Your CURRENT public IP allowlisted (also at API Access page).
#   3. user_name and api_user typically the same (your Namecheap username).
#
# When the apply IP changes (new home network, new VPN exit, new self-hosted
# runner), update both the allowlist on namecheap.com AND TF_VAR_namecheap_client_ip.

provider "namecheap" {
  user_name   = var.namecheap_user_name
  api_user    = var.namecheap_api_user
  api_key     = var.namecheap_api_key
  client_ip   = var.namecheap_client_ip
  use_sandbox = false
}
