#
# Harbor
#

variable "harbor_url" {
  description = "Harbor URL"
  type        = string
}

variable "harbor_username" {
  description = "Harbor username"
  type        = string
}

variable "harbor_password" {
  description = "Harbor password"
  type        = string
}

variable "harbor_bearer_token" {
  description = "Harbor bearer token"
  type        = string
}

variable "harbor_tls_insecure" {
  description = "Harbor insecure"
  type        = bool
  default     = false
}

variable "harbor_api_version" {
  description = "Harbor API version"
  type        = number
  default     = 2
}

variable "harbor_keycloak_endpoint" {
  description = "Harbor keycloak endpoint"
  type        = string
}

variable "harbor_keycloak_client_id" {
  description = "Harbor keycloak client id"
  type        = string
}

variable "harbor_keycloak_client_secret" {
  description = "Harbor keycloak client secret"
  type        = string
}

variable "harbor_keycloak_verify_cert" {
  description = "Harbor keycloak verify cert"
  type        = bool
  default     = true
}

variable "harbor_keycloak_scopes" {
  description = "Harbor keycloak scopes"
  type        = string
  default     = "openid,email,profile,roles"
}

variable "harbor_keycloak_groups_claim" {
  description = "Harbor keycloak groups claim"
  type        = string
}

variable "harbor_keycloak_user_claim" {
  description = "Harbor keycloak user claim"
  type        = string
  default     = "name"
}

variable "harbor_keycloak_admin_group" {
  description = "Harbor keycloak admin group"
  type        = string
}
