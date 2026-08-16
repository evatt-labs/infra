# Domain registration and delegation root
#
# Retains evattlabs.com at Namecheap and manages ONLY its nameserver
# delegation, consuming the Azure DNS nameservers through the public-dns
# root's output contract. Applying this root IS the DNS cutover; it requires
# a manually approved window (stack.yaml approval: apply).
#
# kraai.dev is not managed here; it belongs to its owning repository.
#
# TRANSITION HAZARD: the legacy ../../../registrar/ root still holds a
# namecheap_domain_records resource for this domain pointing at Cloudflare.
# Do not apply the legacy root after cutover; remove it per the migration
# doc's decommission step.

data "terraform_remote_state" "public_dns" {
  backend = "azurerm"

  config = {
    resource_group_name  = "rg-tfstate-prod-eus2-001"
    storage_account_name = "sttfstateprodaf7954"
    container_name       = "tfstate"
    key                  = "platform/public-dns.tfstate"
    use_azuread_auth     = true
    subscription_id      = var.subscription_id
  }
}

locals {
  # Azure emits FQDNs with trailing dots; Namecheap wants bare hostnames.
  azure_nameservers = [
    for ns in data.terraform_remote_state.public_dns.outputs.name_servers :
    trimsuffix(ns, ".")
  ]
}

resource "namecheap_domain_records" "evattlabs_com" {
  domain      = "evattlabs.com"
  mode        = "OVERWRITE"
  nameservers = local.azure_nameservers
}
