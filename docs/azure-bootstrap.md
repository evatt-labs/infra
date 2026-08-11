# Azure tenant bootstrap

This document separates one-time tenant trust establishment from the resources
that Terraform manages continuously.

## Discovered tenant

- Tenant: `Evatt Labs` (`evattlabs.com`)
- Subscription: `Azure subscription 1`
- The operator is Global Administrator in Microsoft Entra ID and Owner on the
  subscription.
- The subscription currently has no resource groups or managed identities.
- The operator does not currently have access to the tenant-root management
  group. Global Administrator and Azure RBAC are separate authorization planes.

Run `scripts/azure-discover.sh` to validate these facts before any bootstrap.

Use the paired scripts around the one-time initialization:

```sh
./scripts/pre-init.sh
./scripts/init.sh
# Create/import/validate the bootstrap resources and durable pipeline identity.
./scripts/post-init.sh
```

`pre-init.sh` validates the expected tenant and subscription, elevates the
signed-in Global Administrator, and creates deterministic temporary human role
assignments. `init.sh` creates the organization management group, places the
bootstrap subscription, creates the remote-state foundation, and establishes the
app registrations, service principals, exact GitHub environment FICs, custom
roles, and initial automation assignments.
`post-init.sh` deletes the exact temporary human assignments and removes the
root-scope elevation. Run the cleanup script even when initialization fails.

No client secret is created. FIC subjects are exact protected GitHub environments
in `evatt-labs/infra`: `bootstrap`, `platform`, `governance`, and `applications`.

## Dependency chain

```text
human Entra Global Administrator
  -> temporary tenant-root User Access Administrator
  -> CAF management-group hierarchy and subscription placement
  -> bootstrap resource group and Azure Storage state backend
  -> bootstrap pipeline identity and minimum RBAC
  -> durable GitHub environment identities
  -> Terraform imports bootstrap resources
  -> revoke temporary tenant-root access
```

## AKS workload identity comparison

Use a user-assigned managed identity with an exact federated identity credential:

- issuer: the AKS OIDC issuer URL
- subject: `system:serviceaccount:<namespace>:<service-account>`
- audience: `api://AzureADTokenExchange`

The workload pod receives a projected Kubernetes service-account token. No
client secret is stored in Kubernetes or Key Vault.

This identity cannot bootstrap the AKS cluster that supplies its issuer. GitHub
Actions deploys the initial cluster under its separate environment identity.

## One-time operations

1. Confirm the active tenant and subscription.
2. Elevate the Global Administrator only long enough to receive tenant-root User
   Access Administrator.
3. Create the CAF management-group hierarchy and move the subscription to its
   intended management group.
4. Register only the resource providers required by the platform design.
5. Create a bootstrap resource group, globally unique storage account, private
   state container, and state-locking/RBAC assignments.
6. Create the pipeline identity selected by the decision gate above.
7. Assign separate state-data and Azure control-plane roles. Avoid `Owner` on the
   durable identity; use `Contributor` plus narrowly scoped role-assignment
   permissions only where Terraform must manage RBAC.
8. Import bootstrap resources into Terraform state.
9. Validate a plan using the pipeline identity.
10. Remove the human tenant-root elevation and verify the pipeline still works.

## Steady-state ownership

Terraform should own management groups, policy assignments, subscription
placement, state resources, managed identities, FICs, and RBAC after bootstrap.
The repository must not contain client secrets, storage account keys, SAS tokens,
or exported access tokens.
