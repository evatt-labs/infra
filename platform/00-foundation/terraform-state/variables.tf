# Root input contract. Values are stable organizational facts, not secrets.

variable "tenant_id" {
  description = "Entra tenant that owns the platform."
  type        = string
  default     = "eed63270-c46f-49e8-9b6c-00228bb37b59"
}

variable "subscription_id" {
  description = "Bootstrap subscription holding the state foundation."
  type        = string
  default     = "af7954f7-e17a-4245-82dd-7bb52d8de69d"
}

variable "location" {
  description = "Azure region for the state foundation."
  type        = string
  default     = "eastus2"
}

variable "state_operator_object_ids" {
  description = "Entra object IDs granted Storage Blob Data Contributor on the state account (human bootstrap operators)."
  type        = map(string)
  default = {
    jordan = "f2a1c09b-9c11-438e-af1a-06395213ac64"
  }
}
