locals {

  sealed-secrets = merge(
    local.helm_defaults,
    {
      name          = local.helm_dependencies[index(local.helm_dependencies.*.name, "sealed-secrets")].name
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "sealed-secrets")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "sealed-secrets")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "sealed-secrets")].version
      namespace     = "sealed-secrets"
      enabled       = false
    },
    var.sealed-secrets
  )

  values_sealed-secrets = <<VALUES
rbac:
  pspEnabled: true
priorityClassName: ${local.priority-class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
VALUES

}

resource "kubernetes_namespace" "sealed-secrets" {
  count = local.sealed-secrets["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.sealed-secrets["namespace"]
    }

    name = local.sealed-secrets["namespace"]
  }
}

resource "helm_release" "sealed-secrets" {
  count                 = local.sealed-secrets["enabled"] ? 1 : 0
  repository            = local.sealed-secrets["repository"]
  name                  = local.sealed-secrets["name"]
  chart                 = local.sealed-secrets["chart"]
  version               = local.sealed-secrets["chart_version"]
  timeout               = local.sealed-secrets["timeout"]
  force_update          = local.sealed-secrets["force_update"]
  recreate_pods         = local.sealed-secrets["recreate_pods"]
  wait                  = local.sealed-secrets["wait"]
  atomic                = local.sealed-secrets["atomic"]
  cleanup_on_fail       = local.sealed-secrets["cleanup_on_fail"]
  dependency_update     = local.sealed-secrets["dependency_update"]
  disable_crd_hooks     = local.sealed-secrets["disable_crd_hooks"]
  disable_webhooks      = local.sealed-secrets["disable_webhooks"]
  render_subchart_notes = local.sealed-secrets["render_subchart_notes"]
  replace               = local.sealed-secrets["replace"]
  reset_values          = local.sealed-secrets["reset_values"]
  reuse_values          = local.sealed-secrets["reuse_values"]
  skip_crds             = local.sealed-secrets["skip_crds"]
  verify                = local.sealed-secrets["verify"]
  values = [
    local.values_sealed-secrets,
    local.sealed-secrets["extra_values"]
  ]
  namespace = kubernetes_namespace.sealed-secrets.*.metadata.0.name[count.index]
}