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
  description = "Public IP from which `tofu apply` runs. Must match an allowlisted IP at Namecheap → API Access."
  type        = string
}
