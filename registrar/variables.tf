variable "namecheap_user_name" {
  description = "Namecheap account username."
  type        = string
}

variable "namecheap_api_user" {
  description = "Namecheap API user (typically the same as the username)."
  type        = string
}

variable "namecheap_api_key" {
  description = "Namecheap API key. Profile → Tools → API Access → Manage."
  type        = string
  sensitive   = true
}

variable "namecheap_client_ip" {
  description = "Public IP from which `tofu apply` runs. Must match an allowlisted IP at Namecheap -> API Access."
  type        = string
}

# === Per-domain feature flags ===
# Gate each domain so registrar can apply ahead of the corresponding dns/
# state existing. Flip a flag to true once that domain's dns/ has been
# applied (see Path 2 runbook in each repo's terraform/dns/README.md).

variable "manage_kraai_dev" {
  description = "Manage kraai.dev NS at Namecheap. Requires kraai-tfstate/dns/ to exist."
  type        = bool
  default     = true
}

variable "manage_evattlabs_com" {
  description = <<EOT
Manage evattlabs.com NS at Namecheap. Requires:
  1. evattlabs-tfstate/dns/ to exist (the CF zone outputs).
  2. evattlabs.com to be in Jordan's Namecheap account.

As of 2026-05-04 the domain is at Tucows (status pendingTransfer);
flip this to true once the transfer to Namecheap completes.
EOT
  type        = bool
  default     = true
}
