#
# Prometheus / Grafana
#
## doc: https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/keycloak/

locals {
  prometheus_grafana_url    = "https://${var.k8s_domain}/prometheus"
  prometheus_grafana_roles  = {
    prometheus-grafana-admin = {
      description = "Admin role for Prometheus / Grafana"
    }
    prometheus-grafana-editor = {
      description = "Editor role for Prometheus / Grafana"
    }
    prometheus-grafana-viewer = {
      description = "Viewer role for Prometheus / Grafana"
    }
  }
}

#
# Client for Prometheus / Grafana
#

resource "keycloak_openid_client" "prometheus_grafana_client" {
  realm_id                        = keycloak_realm.devops.id
  enabled                         = true

  # Settings
  ## General settings
  client_id                       = "prometheus-grafana"
  name                            = "Prometheus / Grafana Client"
  description                     = "Client for Prometheus / Grafana"

  ## Access settings
  root_url                        = local.prometheus_grafana_url
  base_url                        = local.prometheus_grafana_url
  valid_redirect_uris             = [ "${local.prometheus_grafana_url}/login/generic_oauth" ]
  valid_post_logout_redirect_uris = [ local.prometheus_grafana_url ]
  web_origins                     = [ local.prometheus_grafana_url ]
  admin_url                       = local.prometheus_grafana_url

  ## Capability config
  access_type                     = "CONFIDENTIAL"
  standard_flow_enabled           = true
  implicit_flow_enabled           = false
  direct_access_grants_enabled    = true

  ## Login settings
  login_theme                     = "keycloak"
}

#
# Realm roles for Prometheus / Grafana
#
resource "keycloak_role" "prometheus_grafana_roles" {
  for_each                        = local.prometheus_grafana_roles

  realm_id                        = keycloak_realm.devops.id
  name                            = each.key
  description                     = each.value.description
}

#
# Client default scopes for Prometheus / Grafana
#

resource "keycloak_openid_client_default_scopes" "prometheus_grafana_client_default_scopes" {
  realm_id                        = keycloak_realm.devops.id
  client_id                       = keycloak_openid_client.prometheus_grafana_client.id
  default_scopes                  = [
    "email",
    "profile",
    keycloak_openid_client_scope.realm_roles.name
  ]
}
