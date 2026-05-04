bucket  = "evattlabs-tfstate"
key     = "registrar/terraform.tfstate"
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
use_lockfile                = true
