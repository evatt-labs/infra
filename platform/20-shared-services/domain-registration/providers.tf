# Namecheap requires API access enabled and the applying IP allowlisted at
# namecheap.com → Profile → Tools → API Access. Update both the allowlist and
# TF_VAR_namecheap_client_ip when the apply IP changes.

provider "namecheap" {
  user_name   = var.namecheap_user_name
  api_user    = var.namecheap_api_user
  api_key     = var.namecheap_api_key
  client_ip   = var.namecheap_client_ip
  use_sandbox = false
}
