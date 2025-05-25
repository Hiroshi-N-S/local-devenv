#
# Harbor
#

terraform {
  required_version = ">= 1.11.0"

  required_providers {
    harbor = {
      source = "goharbor/harbor"
      version = ">= 3.0.0"
    }
  }
}

provider "harbor" {
  url           = var.harbor_url
  username      = var.harbor_username
  password      = var.harbor_password
  bearer_token  = var.harbor_bearer_token
  insecure      = var.harbor_tls_insecure
  api_version   = var.harbor_api_version
}
