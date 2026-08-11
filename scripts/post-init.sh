#!/usr/bin/env bash
set -euo pipefail

readonly EXPECTED_TENANT_ID="${AZURE_TENANT_ID:-eed63270-c46f-49e8-9b6c-00228bb37b59}"
readonly EXPECTED_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-af7954f7-e17a-4245-82dd-7bb52d8de69d}"
readonly MG_CONTRIBUTOR_ASSIGNMENT_ID="${MG_CONTRIBUTOR_ASSIGNMENT_ID:-9ca45215-78b4-5227-b8cb-f22aa5d45446}"
readonly POLICY_CONTRIBUTOR_ASSIGNMENT_ID="${POLICY_CONTRIBUTOR_ASSIGNMENT_ID:-57209131-f558-521d-9434-52930bda84cf}"

active_tenant_id="$(az account show --query tenantId --output tsv)"
active_subscription_id="$(az account show --query id --output tsv)"

if [[ "${active_tenant_id}" != "${EXPECTED_TENANT_ID}" ]]; then
  echo "Refusing to continue: active tenant is ${active_tenant_id}, expected ${EXPECTED_TENANT_ID}." >&2
  exit 1
fi

if [[ "${active_subscription_id}" != "${EXPECTED_SUBSCRIPTION_ID}" ]]; then
  echo "Refusing to continue: active subscription is ${active_subscription_id}, expected ${EXPECTED_SUBSCRIPTION_ID}." >&2
  exit 1
fi

user_object_id="$(az ad signed-in-user show --query id --output tsv)"
user_principal_name="$(az ad signed-in-user show --query userPrincipalName --output tsv)"
root_management_group_scope="/providers/Microsoft.Management/managementGroups/${EXPECTED_TENANT_ID}"

delete_assignment_if_present() {
  local assignment_id="$1"
  local assignment_scope="$2"
  local assignment_resource_id="${assignment_scope}/providers/Microsoft.Authorization/roleAssignments/${assignment_id}"

  if az role assignment show --ids "${assignment_resource_id}" --output none 2>/dev/null; then
    az role assignment delete --ids "${assignment_resource_id}"
  fi
}

echo "Removing only the temporary role assignments created by scripts/pre-init.sh."
delete_assignment_if_present "${POLICY_CONTRIBUTOR_ASSIGNMENT_ID}" "${root_management_group_scope}"
delete_assignment_if_present "${MG_CONTRIBUTOR_ASSIGNMENT_ID}" "${root_management_group_scope}"

echo "Removing root-scope User Access Administrator elevation from ${user_principal_name}."
if az role assignment list \
  --assignee-object-id "${user_object_id}" \
  --role "User Access Administrator" \
  --scope "/" \
  --query 'length(@)' \
  --output tsv | grep -qxv '0'; then
  az role assignment delete \
    --assignee-object-id "${user_object_id}" \
    --role "User Access Administrator" \
    --scope "/"
fi

echo "Temporary bootstrap access has been removed."

