locals {
  priority_class_ds = merge(
    {
      create = true
      name   = "kubernetes-addons-ds"
      value  = "10000"

    },
    var.priority_class_ds
  )
  priority_class = merge(
    {
      create = true
      name   = "kubernetes-addons"
      value  = "9000"

    },
    var.priority_class
  )
}

resource "kubernetes_priority_class" "kubernetes_addons_ds" {
  count = local.priority_class_ds["create"] ? 1 : 0
  metadata {
    name = local.priority_class_ds["name"]
  }

  value = local.priority_class_ds["value"]
}

resource "kubernetes_priority_class" "kubernetes_addons" {
  count = local.priority_class["create"] ? 1 : 0
  metadata {
    name = local.priority_class["name"]
  }

  value = local.priority_class["value"]
}
