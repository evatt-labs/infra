# Root input contract. Registrar credentials arrive via TF_VAR_* environment
# variables from sops exec-env (secrets/dev.enc.yaml); never commit values.

variable "subscription_id" {
  description = "Subscription holding the Terraform state backend."
  type        = string
  default     = "af7954f7-e17a-4245-82dd-7bb52d8de69d"
}

variable "namecheap_user_name" {
  description = "Namecheap account username."
  type        = string
}

variable "namecheap_api_user" {
  description = "Namecheap API user (typically same as user_name)."
  type        = string
}

variable "namecheap_api_key" {
  description = "Namecheap API key."
  type        = string
  sensitive   = true
}

variable "namecheap_client_ip" {
  description = "Public IP allowlisted for Namecheap API access."
  type        = string
}
