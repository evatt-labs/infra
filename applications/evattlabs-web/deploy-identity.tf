# Deployment identity for the website's GitHub Actions pipeline.
#
# The jmevatt/evattlabs repo exchanges its GitHub OIDC token for this
# identity; the workflow then fetches the SWA deployment token at runtime via
# listSecrets. No client secret or long-lived deployment token is stored.

resource "azuread_application" "site_deploy" {
  display_name     = "spn-evattlabsweb-deploy-prod-001"
  sign_in_audience = "AzureADMyOrg"
}

resource "azuread_service_principal" "site_deploy" {
  client_id = azuread_application.site_deploy.client_id
}

resource "azuread_application_federated_identity_credential" "site_deploy_main" {
  application_id = azuread_application.site_deploy.id
  display_name   = "github-evattlabs-main"
  description    = "Exact GitHub branch trust for website deploys"
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:jmevatt/evattlabs:ref:refs/heads/main"
  audiences      = ["api://AzureADTokenExchange"]
}

# Narrow role: read the static site and list its deployment secret. No write
# access to the resource or anything else in the subscription.
resource "azurerm_role_definition" "swa_deployer" {
  name        = "Evatt Labs Static Web App Deployer"
  scope       = azurerm_static_web_app.site.id
  description = "Reads a static web app and lists its deployment secrets."

  permissions {
    actions = [
      "Microsoft.Web/staticSites/read",
      "Microsoft.Web/staticSites/listsecrets/action",
    ]
  }

  assignable_scopes = [azurerm_static_web_app.site.id]
}

resource "azurerm_role_assignment" "site_deploy" {
  scope              = azurerm_static_web_app.site.id
  role_definition_id = azurerm_role_definition.swa_deployer.role_definition_resource_id
  principal_id       = azuread_service_principal.site_deploy.object_id
  principal_type     = "ServicePrincipal"
}

output "site_deploy_client_id" {
  description = "Client ID the website workflow passes to azure/login."
  value       = azuread_application.site_deploy.client_id
}
