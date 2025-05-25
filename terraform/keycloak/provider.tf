#
# Keycloak
#

terraform {
  required_version = ">= 1.11.0"

  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = ">= 4.0.0"
    }
  }
}

provider "keycloak" {
  client_id                 = var.keycloak_client_id
  client_secret             = var.keycloak_client_secret
  url                       = var.keycloak_url
  tls_insecure_skip_verify  = var.keycloak_tls_insecure
}
