#
# Harbor
#
## doc: https://goharbor.io/docs/2.6.0/administration/configure-authentication/oidc-auth/

locals {
  harbor_url      = "https://${var.nas_domain}:8443"
  harbor_roles    = {
    harbor-admin = {
      description = "Admin role for Harbor"
    }
    harbor-user = {
      description = "User role for Harbor"
    }
  }
}

#
# Client for Harbor
#

resource "keycloak_openid_client" "harbor_client" {
  realm_id                        = keycloak_realm.devops.id
  enabled                         = true

  # Settings
  ## General settings
  client_id                       = "harbor"
  name                            = "Harbor Client"
  description                     = "Client for Harbor"

  ## Access settings
  root_url                        = local.harbor_url
  base_url                        = "/"
  valid_redirect_uris             = [ "${local.harbor_url}/c/oidc/callback" ]
  valid_post_logout_redirect_uris = [ local.harbor_url ]
  web_origins                     = [ local.harbor_url ]
  admin_url                       = local.harbor_url

  ## Capability config
  access_type                     = "CONFIDENTIAL"
  standard_flow_enabled           = true
  direct_access_grants_enabled    = true

  ## Login settings
  login_theme                     = "keycloak"
}

#
# Realm roles for Harbor
#
resource "keycloak_role" "harbor_roles" {
  for_each                        = local.harbor_roles

  realm_id                        = keycloak_realm.devops.id
  name                            = each.key
  description                     = each.value.description
}

#
# Client default scopes
#

resource "keycloak_openid_client_default_scopes" "harbor_client_default_scopes" {
  realm_id                        = keycloak_realm.devops.id
  client_id                       = keycloak_openid_client.harbor_client.id
  default_scopes                  = [
    "email",
    "profile",
    keycloak_openid_client_scope.realm_roles.name
  ]
}
