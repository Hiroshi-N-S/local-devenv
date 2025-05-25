#
# MinIO
#
## doc: https://min.io/docs/minio/macos/operations/external-iam/configure-keycloak-identity-management.html

locals {
  minio_url     = "https://${var.nas_domain}:8443/minio"
  minio_groups  = {
    minio-consoleAdmin = {
      policy    = "consoleAdmin"
    }
    minio-diagnostics = {
      policy    = "diagnostics"
    }
    minio-readonly = {
      policy    = "readonly"
    }
    minio-readwrite = {
      policy    = "readwrite"
    }
    minio-writeonly = {
      policy    = "writeonly"
    }
  }
}

#
# Client for MinIO
#

resource "keycloak_openid_client" "minio_client" {
  realm_id                        = keycloak_realm.devops.id
  enabled                         = true

  # Settings
  ## General settings
  client_id                       = "minio"
  name                            = "MinIO Client"
  description                     = "Client for MinIO"

  ## Access settings
  root_url                        = local.minio_url
  base_url                        = "/realms/devops/account/"
  valid_redirect_uris             = [ "*" ]
  valid_post_logout_redirect_uris = [ local.minio_url ]
  web_origins                     = [ local.minio_url ]
  admin_url                       = local.minio_url

  ## Capability config
  access_type                     = "CONFIDENTIAL"
  standard_flow_enabled           = true
  direct_access_grants_enabled    = true

  ## Login settings
  login_theme                     = "keycloak"

  # Keys
  extra_config = {
    "use.jwks.url"                = true
  }

  # Advanced settings
  access_token_lifespan           = "3600"
}

#
# Client scope for MinIO
#

resource "keycloak_openid_client_scope" "minio_authorization" {
  realm_id                        = keycloak_realm.devops.id
  name                            = "minio-authorization"
  description                     = "Client scope for MinIO authorization"
  include_in_token_scope          = true
}

#
# Client default scopes
#

resource "keycloak_openid_client_default_scopes" "minio_client_default_scopes" {
  realm_id                        = keycloak_realm.devops.id
  client_id                       = keycloak_openid_client.minio_client.id
  default_scopes                  = [
    "profile",
    "roles",
    keycloak_openid_client_scope.minio_authorization.name
  ]
}

#
# User attribute mapper for MinIO
#

resource "keycloak_openid_user_attribute_protocol_mapper" "minio-policy-mapper" {
  realm_id                        = keycloak_realm.devops.id
  client_scope_id                 = keycloak_openid_client_scope.minio_authorization.id
  name                            = "minio-policy-mapper"
  user_attribute                  = "policy"
  claim_name                      = "policy"
  claim_value_type                = "String"
  add_to_id_token                 = true
  add_to_access_token             = true
  add_to_userinfo                 = true
  multivalued                     = true
  aggregate_attributes            = true
}

#
# Groups for MinIO
#

resource "keycloak_group" "minio_groups" {
  for_each = local.minio_groups

  realm_id                        = keycloak_realm.devops.id
  name                            = each.key
  attributes                      = {
    "policy" = each.value.policy
  }
}
