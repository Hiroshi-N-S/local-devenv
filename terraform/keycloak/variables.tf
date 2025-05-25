#
# Keycloak
#

variable "keycloak_client_id" {
  description = "Keycloak client_id"
  type        = string
}

variable "keycloak_client_secret" {
  description = "Keycloak client_secret"
  type        = string
}

variable "keycloak_url" {
  description = "Keycloak URL"
  type        = string
}

variable "keycloak_tls_insecure" {
  description = "Keycloak tls_insecure_skip_verify"
  type        = bool
  default     = false
}
