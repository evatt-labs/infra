# Root input contract. Values are stable organizational facts, not secrets.

variable "tenant_id" {
  description = "Entra tenant that owns the platform."
  type        = string
  default     = "eed63270-c46f-49e8-9b6c-00228bb37b59"
}

variable "subscription_id" {
  description = "Subscription hosting the public website workload."
  type        = string
  default     = "af7954f7-e17a-4245-82dd-7bb52d8de69d"
}

variable "location" {
  description = "Azure region for the website workload."
  type        = string
  default     = "eastus2"
}
