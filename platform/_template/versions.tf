# Tool and provider version contract
#
# Pin Terraform and provider versions to tested ranges. Commit dependency lock
# files for deployable roots after initialization; reusable modules should state
# minimum compatible versions without over-constraining callers.

terraform {
  required_version = ">= 1.9, < 2.0"
}

