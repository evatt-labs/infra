#!/usr/bin/env bash
set -euo pipefail

expected_tenant="${AZURE_TENANT_ID:-}"
expected_subscription="${AZURE_SUBSCRIPTION_ID:-}"

active_tenant="$(az account show --query tenantId --output tsv)"
active_subscription="$(az account show --query id --output tsv)"

if [[ -n "${expected_tenant}" && "${active_tenant}" != "${expected_tenant}" ]]; then
  echo "Active tenant does not match AZURE_TENANT_ID" >&2
  exit 1
fi

if [[ -n "${expected_subscription}" && "${active_subscription}" != "${expected_subscription}" ]]; then
  echo "Active subscription does not match AZURE_SUBSCRIPTION_ID" >&2
  exit 1
fi

az account show \
  --query '{tenantId:tenantId,tenant:tenantDisplayName,domain:tenantDefaultDomain,subscriptionId:id,subscription:name,user:user.name}' \
  --output json

az ad signed-in-user show \
  --query '{id:id,displayName:displayName,userPrincipalName:userPrincipalName}' \
  --output json

az rest \
  --method get \
  --url 'https://graph.microsoft.com/v1.0/me/memberOf/microsoft.graph.directoryRole?$select=displayName,roleTemplateId' \
  --query 'value[].{displayName:displayName,roleTemplateId:roleTemplateId}' \
  --output json

az role assignment list \
  --assignee "$(az ad signed-in-user show --query id --output tsv)" \
  --all \
  --include-inherited \
  --query '[].{role:roleDefinitionName,scope:scope}' \
  --output json

if ! az rest \
  --method get \
  --url 'https://management.azure.com/providers/Microsoft.Management/managementGroups?api-version=2021-04-01' \
  --query 'value[].{name:name,displayName:properties.displayName,parent:properties.details.parent.id}' \
  --output json; then
  echo "Management-group discovery failed. Tenant-root Azure RBAC access may not be elevated." >&2
fi

az group list --query '[].{name:name,location:location}' --output json
az identity list --query '[].{name:name,resourceGroup:resourceGroup,clientId:clientId,id:id}' --output json

