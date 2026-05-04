terraform {
  backend "s3" {
    # Values supplied via backend.hcl.
    # Init: tofu init -backend-config=backend.hcl
  }
}
