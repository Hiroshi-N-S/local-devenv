#
# Users
#

locals {
  groups      = {
    admin: {
      additional_group_ids = [
        keycloak_group.minio_groups["minio-consoleAdmin"].id
      ]
    }
  }
}

#
# Users for `devops` realm
#

resource "keycloak_user" "devops_users" {
  for_each    =  var.users

  realm_id    = keycloak_realm.devops.id
  username    = each.key
  email       = each.value.email
  first_name  = each.value.first_name
  last_name   = each.value.last_name
  initial_password {
    value     = each.key
    temporary = true
  }
}

#
# Groups for `devops` realm
#

resource "keycloak_group" "devops_groups" {
  for_each    = local.groups

  realm_id    = keycloak_realm.devops.id
  name        = each.key
}

#
# User-Groups for `devops` realm
#

resource "keycloak_user_groups" "devops_user_groups" {
  for_each    = var.users

  realm_id    = keycloak_realm.devops.id
  user_id     = keycloak_user.devops_users[each.key].id
  group_ids   = concat(
    [
      keycloak_group.devops_groups[each.value.group_name].id
    ],
    local.groups[each.value.group_name].additional_group_ids
  )
}
