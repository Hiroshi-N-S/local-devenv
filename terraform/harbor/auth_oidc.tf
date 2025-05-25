#
# Auth configurations
#

resource "harbor_config_auth" "oidc" {
  auth_mode           = "oidc_auth"
  primary_auth_mode   = true
  oidc_name           = "KEYCLOAK"
  oidc_endpoint       = var.harbor_keycloak_endpoint
  oidc_client_id      = var.harbor_keycloak_client_id
  oidc_client_secret  = var.harbor_keycloak_client_secret
  oidc_scope          = var.harbor_keycloak_scopes
  oidc_groups_claim   = var.harbor_keycloak_groups_claim
  oidc_verify_cert    = var.harbor_keycloak_verify_cert
  oidc_auto_onboard   = false
  oidc_user_claim     = var.harbor_keycloak_user_claim
  oidc_admin_group    = var.harbor_keycloak_admin_group
}
