# ============================================================================
# Namecheap -- domain ownership + nameserver delegation to Cloudflare.
# ============================================================================
#
# Reads each Cloudflare zone's assigned nameservers via remote state from the
# zone's owning repo:
#   - evattlabs.com nameservers come from this repo's ../dns/ state
#   - kraai.dev nameservers come from kraai-infra's terraform/dns/ state
#
# Both states live in their respective tfstate buckets:
#   - evattlabs-tfstate/dns/terraform.tfstate  (this repo's dns/ subdir)
#   - kraai-tfstate/dns/terraform.tfstate      (kraai-infra repo)
#
# Cross-repo state read works because they're both in R2, accessed via the
# same r2 profile.
#
# Each domain is gated on a feature flag (var.manage_<domain>) so this
# tofu root can apply before all per-domain dns/ states exist.

# === Remote state for kraai.dev nameservers ===
data "terraform_remote_state" "kraai_dns" {
  count   = var.manage_kraai_dev ? 1 : 0
  backend = "s3"

  config = {
    bucket  = "kraai-tfstate"
    key     = "dns/terraform.tfstate"
    region  = "auto"
    profile = "r2"

    endpoints = {
      s3 = "https://0eff878f6bcf777a3e51e2c1c01ca0a4.r2.cloudflarestorage.com"
    }

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}

# === Remote state for evattlabs.com nameservers ===
data "terraform_remote_state" "evattlabs_dns" {
  count   = var.manage_evattlabs_com ? 1 : 0
  backend = "s3"

  config = {
    bucket  = "evattlabs-tfstate"
    key     = "dns/terraform.tfstate"
    region  = "auto"
    profile = "r2"

    endpoints = {
      s3 = "https://0eff878f6bcf777a3e51e2c1c01ca0a4.r2.cloudflarestorage.com"
    }

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}

# === kraai.dev -- delegate NS to Cloudflare ===
resource "namecheap_domain_records" "kraai_dev" {
  count       = var.manage_kraai_dev ? 1 : 0
  domain      = "kraai.dev"
  mode        = "OVERWRITE"
  nameservers = data.terraform_remote_state.kraai_dns[0].outputs.kraai_dev_name_servers
}

# === evattlabs.com -- delegate NS to Cloudflare ===
resource "namecheap_domain_records" "evattlabs_com" {
  count       = var.manage_evattlabs_com ? 1 : 0
  domain      = "evattlabs.com"
  mode        = "OVERWRITE"
  nameservers = data.terraform_remote_state.evattlabs_dns[0].outputs.evattlabs_com_name_servers
}
