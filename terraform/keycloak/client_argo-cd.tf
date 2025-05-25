#
# Argo CD
#
## doc: https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/keycloak/

locals {
  argo_cd_url = "https://${var.k8s_domain}/cd"
  argo_cd_roles    = {
    argo-cd-admin = {
      description = "Admin role for Argo CD"
    }
    argo-cd-readonly = {
      description = "Readonly role for Argo CD"
    }
  }
}

#
# Client for Argo CD
#

resource "keycloak_openid_client" "argo_cd_client" {
  realm_id                        = keycloak_realm.devops.id
  enabled                         = true

  # General settings
  client_id                       = "argo-cd"
  name                            = "Argo CD Client"
  description                     = "Client for Argo CD"

  # Capability config
  access_type                     = "CONFIDENTIAL"
  standard_flow_enabled           = true
  direct_access_grants_enabled    = true

  # Access settings
  root_url                        = local.argo_cd_url
  base_url                        = "/applications"
  valid_redirect_uris             = [ "${local.argo_cd_url}/auth/callback" ]
  valid_post_logout_redirect_uris = [ local.argo_cd_url ]
  web_origins                     = [ local.argo_cd_url ]
  admin_url                       = local.argo_cd_url

  # Login settings
  login_theme                     = "keycloak"
}

#
# Realm roles for Argo CD
#

resource "keycloak_role" "argo_cd_roles" {
  for_each                        = local.argo_cd_roles

  realm_id                        = keycloak_realm.devops.id
  name                            = each.key
  description                     = each.value.description
}

#
# Client default scopes for Argo CD
#

resource "keycloak_openid_client_default_scopes" "argo_cd_client_default_scopes" {
  realm_id                        = keycloak_realm.devops.id
  client_id                       = keycloak_openid_client.argo_cd_client.id
  default_scopes                  = [
    "profile",
    keycloak_openid_client_scope.realm_roles.name
  ]
}
