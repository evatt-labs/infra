#!/usr/bin/env bash
set -euo pipefail

# Azure identity-platform foundation bootstrap
#
# This script creates only resources required before Terraform can use remote
# state. It is idempotent and validates the active tenant/subscription before any
# write. Run scripts/pre-init.sh first and scripts/post-init.sh afterward.
#
# Azure resources cannot be deployed directly into a management group. The
# bootstrap subscription is placed beneath the organization management group;
# the state resource group, storage account, and container live in that
# subscription. Terraform must subsequently import and own every created object.
#
# This script also establishes the secretless pipeline trust roots that Terraform
# must subsequently import. It creates no passwords, certificates, broad Owner
# assignments, or durable root User Access Administrator assignments.

readonly EXPECTED_TENANT_ID="${AZURE_TENANT_ID:-eed63270-c46f-49e8-9b6c-00228bb37b59}"
readonly EXPECTED_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-af7954f7-e17a-4245-82dd-7bb52d8de69d}"
readonly ORGANIZATION_MG_ID="${AZURE_ORGANIZATION_MG_ID:-evattlabs}"
readonly ORGANIZATION_MG_DISPLAY_NAME="${AZURE_ORGANIZATION_MG_DISPLAY_NAME:-Evatt Labs}"
readonly STATE_LOCATION="${AZURE_STATE_LOCATION:-eastus2}"
readonly STATE_RESOURCE_GROUP="${AZURE_STATE_RESOURCE_GROUP:-rg-tfstate-prod-eus2-001}"
readonly STATE_CONTAINER="${AZURE_STATE_CONTAINER:-tfstate}"
readonly GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-evatt-labs/infra}"
readonly GITHUB_OIDC_ISSUER="https://token.actions.githubusercontent.com"
readonly GITHUB_OIDC_AUDIENCE="api://AzureADTokenExchange"
readonly BILLING_ACCOUNT_NAME="${AZURE_BILLING_ACCOUNT_NAME:?Set AZURE_BILLING_ACCOUNT_NAME for the target MCA account.}"
readonly BILLING_PROFILE_NAME="${AZURE_BILLING_PROFILE_NAME:?Set AZURE_BILLING_PROFILE_NAME for the target MCA billing profile.}"
readonly INVOICE_SECTION_NAME="${AZURE_INVOICE_SECTION_NAME:?Set AZURE_INVOICE_SECTION_NAME for the target MCA invoice section.}"

readonly MG_HIERARCHY_ROLE_ID="${MG_HIERARCHY_ROLE_ID:-0c55b9be-bfeb-5e04-a863-2f1d8c071e41}"
readonly SUBSCRIPTION_VENDING_ROLE_ID="${SUBSCRIPTION_VENDING_ROLE_ID:-cd503b7c-095d-5a59-b8db-71b03f93775e}"
readonly PLATFORM_RBAC_ROLE_ID="${PLATFORM_RBAC_ROLE_ID:-aab27e09-fbcc-55f6-a9a0-6d84e9232c93}"
readonly LANDING_ZONE_RBAC_ROLE_ID="${LANDING_ZONE_RBAC_ROLE_ID:-7188bbaa-ecdf-5eb1-8dcb-ac0f216614bb}"

subscription_fragment="${EXPECTED_SUBSCRIPTION_ID//-/}"
readonly STATE_STORAGE_ACCOUNT="${AZURE_STATE_STORAGE_ACCOUNT:-sttfstateprod${subscription_fragment:0:6}}"

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

tenant_root_scope="/providers/Microsoft.Management/managementGroups/${EXPECTED_TENANT_ID}"
organization_mg_scope="/providers/Microsoft.Management/managementGroups/${ORGANIZATION_MG_ID}"

create_or_update_custom_role() {
  local role_id="$1"
  local role_name="$2"
  local description="$3"
  local actions_json="$4"
  local role_file

  role_file="$(mktemp)"
  jq -n \
    --arg role_id "${role_id}" \
    --arg role_name "${role_name}" \
    --arg description "${description}" \
    --arg scope "${tenant_root_scope}" \
    --argjson actions "${actions_json}" \
    '{Name: $role_name, Id: $role_id, IsCustom: true, Description: $description, Actions: $actions, NotActions: [], DataActions: [], NotDataActions: [], AssignableScopes: [$scope]}' \
    >"${role_file}"

  if az role definition list --name "${role_id}" --query 'length(@)' --output tsv | grep -qx '0'; then
    az role definition create --role-definition "@${role_file}" --output none
  else
    az role definition update --role-definition "@${role_file}" --output none
  fi
  rm -f -- "${role_file}"
}

ensure_application() {
  local display_name="$1"
  local matches
  local application_id
  local application_object_id
  local service_principal_object_id

  matches="$(az ad app list --display-name "${display_name}" --query 'length(@)' --output tsv)"
  if [[ "${matches}" -gt 1 ]]; then
    echo "Refusing to continue: multiple app registrations are named ${display_name}." >&2
    exit 1
  fi

  if [[ "${matches}" -eq 0 ]]; then
    application_id="$(az ad app create --display-name "${display_name}" --sign-in-audience AzureADMyOrg --query appId --output tsv)"
  else
    application_id="$(az ad app list --display-name "${display_name}" --query '[0].appId' --output tsv)"
  fi

  application_object_id="$(az ad app show --id "${application_id}" --query id --output tsv)"
  service_principal_object_id="$(az ad sp list --filter "appId eq '${application_id}'" --query '[0].id' --output tsv)"
  if [[ -z "${service_principal_object_id}" ]]; then
    service_principal_object_id="$(az ad sp create --id "${application_id}" --query id --output tsv)"
  fi

  jq -n \
    --arg app_id "${application_id}" \
    --arg app_object_id "${application_object_id}" \
    --arg sp_object_id "${service_principal_object_id}" \
    '{app_id: $app_id, app_object_id: $app_object_id, sp_object_id: $sp_object_id}'
}

ensure_github_fic() {
  local application_object_id="$1"
  local environment_name="$2"
  local credential_name="github-${environment_name}"
  local subject="repo:${GITHUB_REPOSITORY}:environment:${environment_name}"
  local credential_file

  if az ad app federated-credential list \
    --id "${application_object_id}" \
    --query "[?name=='${credential_name}' && issuer=='${GITHUB_OIDC_ISSUER}' && subject=='${subject}' && audiences[0]=='${GITHUB_OIDC_AUDIENCE}'] | length(@)" \
    --output tsv | grep -qx '1'; then
    return
  fi

  if az ad app federated-credential list --id "${application_object_id}" --query "[?name=='${credential_name}'] | length(@)" --output tsv | grep -qxv '0'; then
    echo "Refusing to replace mismatched FIC ${credential_name} on application ${application_object_id}." >&2
    exit 1
  fi

  credential_file="$(mktemp)"
  jq -n \
    --arg name "${credential_name}" \
    --arg issuer "${GITHUB_OIDC_ISSUER}" \
    --arg subject "${subject}" \
    --arg audience "${GITHUB_OIDC_AUDIENCE}" \
    '{name: $name, issuer: $issuer, subject: $subject, audiences: [$audience], description: "Exact GitHub environment trust"}' \
    >"${credential_file}"
  az ad app federated-credential create --id "${application_object_id}" --parameters "@${credential_file}" --output none
  rm -f -- "${credential_file}"
}

ensure_role_assignment() {
  local assignment_name="$1"
  local principal_object_id="$2"
  local role="$3"
  local scope="$4"

  if ! az role assignment show --ids "${scope}/providers/Microsoft.Authorization/roleAssignments/${assignment_name}" --output none 2>/dev/null; then
    az role assignment create \
      --name "${assignment_name}" \
      --assignee-object-id "${principal_object_id}" \
      --assignee-principal-type ServicePrincipal \
      --role "${role}" \
      --scope "${scope}" \
      --output none
  fi
}

ensure_graph_app_role() {
  local principal_object_id="$1"
  local graph_service_principal_id="$2"
  local app_role_id="$3"

  if az rest \
    --method get \
    --url "https://graph.microsoft.com/v1.0/servicePrincipals/${principal_object_id}/appRoleAssignments" \
    --query "value[?resourceId=='${graph_service_principal_id}' && appRoleId=='${app_role_id}'] | length(@)" \
    --output tsv | grep -qx '0'; then
    az rest \
      --method post \
      --url "https://graph.microsoft.com/v1.0/servicePrincipals/${principal_object_id}/appRoleAssignments" \
      --body "$(jq -n --arg principal_id "${principal_object_id}" --arg resource_id "${graph_service_principal_id}" --arg app_role_id "${app_role_id}" '{principalId: $principal_id, resourceId: $resource_id, appRoleId: $app_role_id}')" \
      --output none
  fi
}

echo "Creating or updating organization management group ${ORGANIZATION_MG_ID}."
management_group_body="$(
  jq -n \
    --arg display_name "${ORGANIZATION_MG_DISPLAY_NAME}" \
    --arg parent_id "${tenant_root_scope}" \
    '{properties: {displayName: $display_name, details: {parent: {id: $parent_id}}}}'
)"

az rest \
  --method put \
  --url "https://management.azure.com${organization_mg_scope}?api-version=2021-04-01" \
  --body "${management_group_body}" \
  --output none

echo "Placing bootstrap subscription beneath ${ORGANIZATION_MG_ID}."
az rest \
  --method put \
  --url "https://management.azure.com${organization_mg_scope}/subscriptions/${EXPECTED_SUBSCRIPTION_ID}?api-version=2020-05-01" \
  --output none

echo "Registering Microsoft.Storage."
az provider register --namespace Microsoft.Storage --wait

echo "Creating or updating state resource group ${STATE_RESOURCE_GROUP}."
az group create \
  --name "${STATE_RESOURCE_GROUP}" \
  --location "${STATE_LOCATION}" \
  --tags \
    environment=prod \
    managed-by=bootstrap \
    workload=terraform-state \
  --output none

if ! az storage account show \
  --name "${STATE_STORAGE_ACCOUNT}" \
  --resource-group "${STATE_RESOURCE_GROUP}" \
  --output none 2>/dev/null; then
  name_available="$(
    az storage account check-name \
      --name "${STATE_STORAGE_ACCOUNT}" \
      --query nameAvailable \
      --output tsv
  )"

  if [[ "${name_available}" != "true" ]]; then
    echo "Storage account name ${STATE_STORAGE_ACCOUNT} is unavailable; set AZURE_STATE_STORAGE_ACCOUNT explicitly." >&2
    exit 1
  fi

  echo "Creating state storage account ${STATE_STORAGE_ACCOUNT}."
  az storage account create \
    --name "${STATE_STORAGE_ACCOUNT}" \
    --resource-group "${STATE_RESOURCE_GROUP}" \
    --location "${STATE_LOCATION}" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --https-only true \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --allow-shared-key-access false \
    --tags \
      environment=prod \
      managed-by=bootstrap \
      workload=terraform-state \
    --output none
fi

storage_account_id="$(
  az storage account show \
    --name "${STATE_STORAGE_ACCOUNT}" \
    --resource-group "${STATE_RESOURCE_GROUP}" \
    --query id \
    --output tsv
)"

echo "Creating state container ${STATE_CONTAINER} through the ARM control plane."
az rest \
  --method put \
  --url "https://management.azure.com${storage_account_id}/blobServices/default/containers/${STATE_CONTAINER}?api-version=2023-05-01" \
  --body '{"properties":{"publicAccess":"None"}}' \
  --output none

echo "Creating or updating least-privilege custom roles."
create_or_update_custom_role \
  "${MG_HIERARCHY_ROLE_ID}" \
  "Evatt Labs Management Group Hierarchy Operator" \
  "Creates, updates, nests, and deletes management groups without placing subscriptions or managing RBAC." \
  '["Microsoft.Management/managementGroups/read","Microsoft.Management/managementGroups/write","Microsoft.Management/managementGroups/delete"]'

create_or_update_custom_role \
  "${SUBSCRIPTION_VENDING_ROLE_ID}" \
  "Evatt Labs Subscription Vending Operator" \
  "Creates MCA subscriptions and places them in management groups without creating management groups or managing RBAC." \
  '["Microsoft.Subscription/aliases/read","Microsoft.Subscription/aliases/write","Microsoft.Subscription/aliases/delete","Microsoft.Management/managementGroups/read","Microsoft.Management/managementGroups/subscriptions/read","Microsoft.Management/managementGroups/subscriptions/write","Microsoft.Management/managementGroups/subscriptions/delete"]'

create_or_update_custom_role \
  "${PLATFORM_RBAC_ROLE_ID}" \
  "Evatt Labs Platform RBAC Operator" \
  "Manages Azure role assignments only at an explicitly assigned platform management-group scope." \
  '["Microsoft.Authorization/roleAssignments/read","Microsoft.Authorization/roleAssignments/write","Microsoft.Authorization/roleAssignments/delete","Microsoft.Authorization/roleDefinitions/read"]'

create_or_update_custom_role \
  "${LANDING_ZONE_RBAC_ROLE_ID}" \
  "Evatt Labs Landing Zone RBAC Operator" \
  "Manages Azure role assignments only at an explicitly assigned landing-zone management-group scope." \
  '["Microsoft.Authorization/roleAssignments/read","Microsoft.Authorization/roleAssignments/write","Microsoft.Authorization/roleAssignments/delete","Microsoft.Authorization/roleDefinitions/read"]'

echo "Creating app registrations, service principals, and exact GitHub environment FICs."
mg_hierarchy_identity="$(ensure_application spn-mghierarchy-prod-001)"
subscription_vending_identity="$(ensure_application spn-subvending-prod-001)"
policy_identity="$(ensure_application spn-policy-prod-001)"
platform_rbac_identity="$(ensure_application spn-rbac-platform-prod-001)"
landing_zone_rbac_identity="$(ensure_application spn-rbac-landingzones-prod-001)"
entra_groups_identity="$(ensure_application spn-entragroups-prod-001)"

ensure_github_fic "$(jq -r .app_object_id <<<"${mg_hierarchy_identity}")" bootstrap
ensure_github_fic "$(jq -r .app_object_id <<<"${subscription_vending_identity}")" bootstrap
ensure_github_fic "$(jq -r .app_object_id <<<"${policy_identity}")" governance
ensure_github_fic "$(jq -r .app_object_id <<<"${platform_rbac_identity}")" platform
ensure_github_fic "$(jq -r .app_object_id <<<"${landing_zone_rbac_identity}")" applications
ensure_github_fic "$(jq -r .app_object_id <<<"${entra_groups_identity}")" platform

echo "Assigning durable Azure control-plane permissions."
ensure_role_assignment \
  "870d7f2f-050a-54ce-baa5-3e21fef8d106" \
  "$(jq -r .sp_object_id <<<"${mg_hierarchy_identity}")" \
  "${MG_HIERARCHY_ROLE_ID}" \
  "${tenant_root_scope}"

ensure_role_assignment \
  "770ebf12-9c90-50dd-bf73-87d26dcb17a7" \
  "$(jq -r .sp_object_id <<<"${subscription_vending_identity}")" \
  "${SUBSCRIPTION_VENDING_ROLE_ID}" \
  "${tenant_root_scope}"

ensure_role_assignment \
  "8190b701-5644-5639-9ed4-a66fc137d10b" \
  "$(jq -r .sp_object_id <<<"${policy_identity}")" \
  "Resource Policy Contributor" \
  "${organization_mg_scope}"

# The platform and landing-zone RBAC identities intentionally receive no role
# assignment here. Their target management groups do not exist yet. Assigning at
# the organization parent would grant inherited access to both branches.

echo "Granting least-privilege Microsoft Graph application permissions."
graph_service_principal_id="$(az ad sp list --filter "appId eq '00000003-0000-0000-c000-000000000000'" --query '[0].id' --output tsv)"
user_read_all_role_id="$(az ad sp show --id "${graph_service_principal_id}" --query "appRoles[?value=='User.Read.All' && contains(allowedMemberTypes, 'Application')].id | [0]" --output tsv)"
group_member_write_role_id="$(az ad sp show --id "${graph_service_principal_id}" --query "appRoles[?value=='GroupMember.ReadWrite.All' && contains(allowedMemberTypes, 'Application')].id | [0]" --output tsv)"

if [[ -z "${user_read_all_role_id}" || -z "${group_member_write_role_id}" ]]; then
  echo "Refusing to continue: required Microsoft Graph application roles were not found." >&2
  exit 1
fi

entra_groups_sp_object_id="$(jq -r .sp_object_id <<<"${entra_groups_identity}")"
ensure_graph_app_role "${entra_groups_sp_object_id}" "${graph_service_principal_id}" "${user_read_all_role_id}"
ensure_graph_app_role "${entra_groups_sp_object_id}" "${graph_service_principal_id}" "${group_member_write_role_id}"

echo "Granting Azure Subscription Creator at the configured MCA invoice section."
billing_scope="/providers/Microsoft.Billing/billingAccounts/${BILLING_ACCOUNT_NAME}/billingProfiles/${BILLING_PROFILE_NAME}/invoiceSections/${INVOICE_SECTION_NAME}"
billing_role_definition_id="$(
  az rest \
    --method get \
    --url "https://management.azure.com${billing_scope}/billingRoleDefinitions?api-version=2024-04-01" \
    --query "value[?properties.roleName=='Azure subscription creator'].id | [0]" \
    --output tsv
)"

if [[ -z "${billing_role_definition_id}" ]]; then
  echo "Refusing to continue: Azure Subscription Creator billing role was not found at ${billing_scope}." >&2
  exit 1
fi

subscription_vending_sp_object_id="$(jq -r .sp_object_id <<<"${subscription_vending_identity}")"
existing_billing_assignments="$(
  az rest \
    --method get \
    --url "https://management.azure.com${billing_scope}/billingRoleAssignments?api-version=2024-04-01" \
    --query "value[?properties.principalId=='${subscription_vending_sp_object_id}' && properties.roleDefinitionId=='${billing_role_definition_id}'] | length(@)" \
    --output tsv
)"

if [[ "${existing_billing_assignments}" == "0" ]]; then
  az rest \
    --method post \
    --url "https://management.azure.com${billing_scope}/createBillingRoleAssignment?api-version=2024-04-01" \
    --body "$(jq -n --arg principal_id "${subscription_vending_sp_object_id}" --arg tenant_id "${EXPECTED_TENANT_ID}" --arg role_definition_id "${billing_role_definition_id}" '{principalId: $principal_id, principalTenantId: $tenant_id, roleDefinitionId: $role_definition_id}')" \
    --output none
fi

jq -n \
  --arg tenant_id "${EXPECTED_TENANT_ID}" \
  --arg subscription_id "${EXPECTED_SUBSCRIPTION_ID}" \
  --arg management_group_id "${ORGANIZATION_MG_ID}" \
  --arg resource_group_name "${STATE_RESOURCE_GROUP}" \
  --arg storage_account_name "${STATE_STORAGE_ACCOUNT}" \
  --arg container_name "${STATE_CONTAINER}" \
  --arg github_repository "${GITHUB_REPOSITORY}" \
  --argjson mg_hierarchy_identity "${mg_hierarchy_identity}" \
  --argjson subscription_vending_identity "${subscription_vending_identity}" \
  --argjson policy_identity "${policy_identity}" \
  --argjson platform_rbac_identity "${platform_rbac_identity}" \
  --argjson landing_zone_rbac_identity "${landing_zone_rbac_identity}" \
  --argjson entra_groups_identity "${entra_groups_identity}" \
  '{
    tenant_id: $tenant_id,
    subscription_id: $subscription_id,
    management_group_id: $management_group_id,
    resource_group_name: $resource_group_name,
    storage_account_name: $storage_account_name,
    container_name: $container_name,
    github_repository: $github_repository,
    identities: {
      management_group_hierarchy: $mg_hierarchy_identity,
      subscription_vending: $subscription_vending_identity,
      policy: $policy_identity,
      platform_rbac: $platform_rbac_identity,
      landing_zone_rbac: $landing_zone_rbac_identity,
      entra_groups: $entra_groups_identity
    }
  }'

echo "Foundation created. Import it into platform/00-foundation before adding further tenant resources."
