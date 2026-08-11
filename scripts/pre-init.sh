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
root_management_group_scope="/providers/Microsoft.Management/managementGroups/${EXPECTED_TENANT_ID}"

echo "Elevating the signed-in Global Administrator to User Access Administrator at root scope."
az rest \
  --method post \
  --url "/providers/Microsoft.Authorization/elevateAccess?api-version=2016-07-01" \
  --output none

echo "Granting temporary management-group bootstrap roles to ${user_object_id}."
az role assignment create \
  --name "${MG_CONTRIBUTOR_ASSIGNMENT_ID}" \
  --assignee-object-id "${user_object_id}" \
  --assignee-principal-type User \
  --role "Management Group Contributor" \
  --scope "${root_management_group_scope}" \
  --output none

az role assignment create \
  --name "${POLICY_CONTRIBUTOR_ASSIGNMENT_ID}" \
  --assignee-object-id "${user_object_id}" \
  --assignee-principal-type User \
  --role "Resource Policy Contributor" \
  --scope "${root_management_group_scope}" \
  --output none

echo "Temporary bootstrap access is active. Always run scripts/post-init.sh when initialization is complete."

