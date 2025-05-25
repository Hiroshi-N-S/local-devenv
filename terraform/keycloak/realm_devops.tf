#
# Realm
#

resource "keycloak_realm" "devops" {
  realm   = "devops"
  enabled = true
}
