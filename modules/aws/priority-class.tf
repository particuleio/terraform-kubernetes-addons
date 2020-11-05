locals {
  priority-class-ds = merge(
    {
      create = true
      name   = "kubernetes-addons-ds"
      value  = "10000"

    },
    var.priority-class-ds
  )
  priority-class = merge(
    {
      create = true
      name   = "kubernetes-addons"
      value  = "9000"

    },
    var.priority-class
  )
}

resource "kubernetes_priority_class" "kubernetes_addons_ds" {
  count = local.priority-class-ds["create"] ? 1 : 0
  metadata {
    name = local.priority-class-ds["name"]
  }

  value = local.priority-class-ds["value"]
}

resource "kubernetes_priority_class" "kubernetes_addons" {
  count = local.priority-class["create"] ? 1 : 0
  metadata {
    name = local.priority-class["name"]
  }

  value = local.priority-class["value"]
}
