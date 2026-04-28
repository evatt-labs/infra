# OpenTofu state backend (Cloudflare R2, S3-compatible).
#
# The google provider auths via Application Default Credentials and is
# unrelated to this file - the two don't fight.
#
# Local prerequisites:
#   1. ~/.aws/credentials has an [r2] profile with R2 access key + secret.
#   2. Bucket exists: `wrangler r2 bucket create evattlabs-tfstate` (one-time).
#
# Init:  tofu init -backend-config=backend.hcl

bucket  = "evattlabs-tfstate"
key     = "gcp/terraform.tfstate"
region  = "auto"
profile = "r2"

endpoints = {
  s3 = "https://0eff878f6bcf777a3e51e2c1c01ca0a4.r2.cloudflarestorage.com"
}

# R2 doesn't speak all of S3's metadata APIs - skip them.
skip_credentials_validation = true
skip_metadata_api_check     = true
skip_region_validation      = true
skip_requesting_account_id  = true
skip_s3_checksum            = true
use_path_style              = true
