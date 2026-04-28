terraform {
  backend "s3" {
    # All values supplied via backend.hcl (gitignored).
    # See backend.hcl.example for the shape.
    #
    # Init:
    #   tofu init -backend-config=backend.hcl -reconfigure
  }
}
