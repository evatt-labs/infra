# Organization-level resources for evattlabs.com.
#
# Each policy below is the de facto baseline for new GCP orgs. We start
# enforced everywhere and override per-folder where needed (e.g. GAM
# project needs SA-key uploads).
#
# All policies use the v2 `google_org_policy_policy` resource.
# v1 (`google_organization_policy`) is deprecated; do not introduce.

# ──────────────────────────────────────────────────────────────────
# Disable service account key upload, org-wide.
# ──────────────────────────────────────────────────────────────────
# This is currently set manually on the org (re-enabled tonight after
# the GAM bootstrap). Importing it under TF management:
#
#   tofu import google_org_policy_policy.disable_sa_key_upload \
#     organizations/493326646328/policies/iam.disableServiceAccountKeyUpload
#
# Per-folder override for /admin (so GAM can rotate its key) is below.

resource "google_org_policy_policy" "disable_sa_key_upload" {
  name   = "organizations/${local.org_id}/policies/iam.disableServiceAccountKeyUpload"
  parent = "organizations/${local.org_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

resource "google_org_policy_policy" "disable_sa_key_upload_admin_override" {
  name   = "${google_folder.admin.name}/policies/iam.disableServiceAccountKeyUpload"
  parent = google_folder.admin.name

  # Allow SA key uploads inside the /admin folder only (where GAM lives).
  spec {
    rules {
      enforce = "FALSE"
    }
  }
}

# ──────────────────────────────────────────────────────────────────
# Disable creation of new SA keys (the *download* path).
# ──────────────────────────────────────────────────────────────────
# Forces use of workload identity / OIDC / impersonation for everything
# except where we explicitly need a static key (GAM).

resource "google_org_policy_policy" "disable_sa_key_creation" {
  name   = "organizations/${local.org_id}/policies/iam.disableServiceAccountKeyCreation"
  parent = "organizations/${local.org_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

resource "google_org_policy_policy" "disable_sa_key_creation_admin_override" {
  name   = "${google_folder.admin.name}/policies/iam.disableServiceAccountKeyCreation"
  parent = google_folder.admin.name

  spec {
    rules {
      enforce = "FALSE"
    }
  }
}

# ──────────────────────────────────────────────────────────────────
# Restrict IAM to only members from evattlabs.com Workspace customer.
# ──────────────────────────────────────────────────────────────────
# Stops accidental IAM grants to random @gmail accounts. Allowed values
# are Cloud Identity customer IDs; ours is C03gqyb4m.

resource "google_org_policy_policy" "allowed_policy_member_domains" {
  name   = "organizations/${local.org_id}/policies/iam.allowedPolicyMemberDomains"
  parent = "organizations/${local.org_id}"

  spec {
    rules {
      values {
        allowed_values = [
          "C03gqyb4m", # evattlabs.com Workspace customer
        ]
      }
    }
  }
}

# ──────────────────────────────────────────────────────────────────
# Disable automatic IAM grants to default service accounts.
# ──────────────────────────────────────────────────────────────────
# Default Compute / App Engine SAs would otherwise auto-receive Editor.
# Kill that.

resource "google_org_policy_policy" "disable_default_sa_grants" {
  name   = "organizations/${local.org_id}/policies/iam.automaticIamGrantsForDefaultServiceAccounts"
  parent = "organizations/${local.org_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# ──────────────────────────────────────────────────────────────────
# Skip default network creation in new projects.
# ──────────────────────────────────────────────────────────────────
# We don't want every new project to get a public default VPC.

resource "google_org_policy_policy" "skip_default_network" {
  name   = "organizations/${local.org_id}/policies/compute.skipDefaultNetworkCreation"
  parent = "organizations/${local.org_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}
