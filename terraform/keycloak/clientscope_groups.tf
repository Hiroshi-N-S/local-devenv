#
# Client scope for Realm roles
#

resource "keycloak_openid_client_scope" "realm_roles" {
  realm_id                        = keycloak_realm.devops.id
  name                            = "realm-roles"
  description                     = "OpenID Connect scope for add user roles to the access token"
  include_in_token_scope          = true
}

resource "keycloak_openid_user_realm_role_protocol_mapper" "realm_role_mapper" {
  realm_id                        = keycloak_realm.devops.id
  client_scope_id                 = keycloak_openid_client_scope.realm_roles.id
  name                            = "realm roles"
  claim_name                      = "groups"
  claim_value_type                = "string"
  multivalued                     = true
  add_to_id_token                 = true
  add_to_access_token             = true
  add_to_userinfo                 = true
}
