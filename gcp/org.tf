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

# ──────────────────────────────────────────────────────────────────
# The four policies below were set by Google's Cloud Setup wizard
# on 2026-01-24. Importing them into TF so they're a single source
# of truth and don't drift silently.
#
#   tofu import google_org_policy_policy.uniform_bucket_level_access \
#     organizations/493326646328/policies/storage.uniformBucketLevelAccess
#   tofu import google_org_policy_policy.essential_contacts_domains \
#     organizations/493326646328/policies/essentialcontacts.allowedContactDomains
#   tofu import google_org_policy_policy.restrict_protocol_forwarding \
#     organizations/493326646328/policies/compute.restrictProtocolForwardingCreationForTypes
#   tofu import google_org_policy_policy.zonal_dns_only \
#     organizations/493326646328/policies/compute.setNewProjectDefaultToZonalDNSOnly
# ──────────────────────────────────────────────────────────────────

# Force uniform bucket-level access on all new GCS buckets (no ACLs).
resource "google_org_policy_policy" "uniform_bucket_level_access" {
  name   = "organizations/${local.org_id}/policies/storage.uniformBucketLevelAccess"
  parent = "organizations/${local.org_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Restrict who can be added as an Essential Contact to evattlabs.com only.
resource "google_org_policy_policy" "essential_contacts_domains" {
  name   = "organizations/${local.org_id}/policies/essentialcontacts.allowedContactDomains"
  parent = "organizations/${local.org_id}"

  spec {
    rules {
      values {
        allowed_values = [
          "@evattlabs.com",
        ]
      }
    }
  }
}

# Limit Protocol Forwarding rule creation to INTERNAL only (no external
# protocol forwarding) - tightens lateral-movement blast radius.
resource "google_org_policy_policy" "restrict_protocol_forwarding" {
  name   = "organizations/${local.org_id}/policies/compute.restrictProtocolForwardingCreationForTypes"
  parent = "organizations/${local.org_id}"

  spec {
    rules {
      values {
        allowed_values = [
          "INTERNAL",
        ]
      }
    }
  }
}

# New projects default to zonal DNS only (faster resolution, no global DNS).
resource "google_org_policy_policy" "zonal_dns_only" {
  name   = "organizations/${local.org_id}/policies/compute.setNewProjectDefaultToZonalDNSOnly"
  parent = "organizations/${local.org_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}
