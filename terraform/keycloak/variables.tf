#
# Users
#

variable "users" {
  description   = "Users"
  type          = map(object({
    email       = string
    first_name  = string
    last_name   = string
    group_name  = string
  }))
}

#
# Domains
#

variable "nas_domain" {
  description = "Synology NAS Domain"
  type        = string
}

variable "k8s_domain" {
  description = "K8S Cluster Domain"
  type        = string
}

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
