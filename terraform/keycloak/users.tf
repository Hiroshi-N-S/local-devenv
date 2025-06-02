#
# Users
#

locals {
  groups      = {
    admin: {
      role_ids = [
        keycloak_role.harbor_roles["harbor-admin"].id,
        keycloak_role.argo_cd_roles["argo-cd-admin"].id,
        keycloak_role.prometheus_grafana_roles["prometheus-grafana-admin"].id
      ]
      additional_group_ids = [
        keycloak_group.minio_groups["minio-consoleAdmin"].id
      ]
    }
    viewer: {
      role_ids = [
        keycloak_role.harbor_roles["harbor-user"].id,
        keycloak_role.argo_cd_roles["argo-cd-readonly"].id,
        keycloak_role.prometheus_grafana_roles["prometheus-grafana-viewer"].id
      ]
      additional_group_ids = [
        keycloak_group.minio_groups["minio-readonly"].id
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
# Group-Roles for `devops` realm
#

resource "keycloak_group_roles" "devops_group_roles" {
  for_each    = local.groups

  realm_id    = keycloak_realm.devops.id
  group_id    = keycloak_group.devops_groups[each.key].id
  role_ids    = each.value.role_ids
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
