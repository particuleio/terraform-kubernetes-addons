locals {
  npd = merge(
    local.helm_defaults,
    {
      name          = local.helm_dependencies[index(local.helm_dependencies.*.name, "node-problem-detector")].name
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "node-problem-detector")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "node-problem-detector")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "node-problem-detector")].version
      namespace     = "node-problem-detector"
      enabled       = false
    },
    var.npd
  )

  values_npd = <<VALUES
rbac:
  pspEnabled: true
priorityClassName: ${local.priority-class-ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}
VALUES

}

resource "kubernetes_namespace" "node-problem-detector" {
  count = local.npd["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.npd["namespace"]
    }

    name = local.npd["namespace"]
  }
}

resource "helm_release" "node-problem-detector" {
  count                 = local.npd["enabled"] ? 1 : 0
  repository            = local.npd["repository"]
  name                  = local.npd["name"]
  chart                 = local.npd["chart"]
  version               = local.npd["chart_version"]
  timeout               = local.npd["timeout"]
  force_update          = local.npd["force_update"]
  recreate_pods         = local.npd["recreate_pods"]
  wait                  = local.npd["wait"]
  atomic                = local.npd["atomic"]
  cleanup_on_fail       = local.npd["cleanup_on_fail"]
  dependency_update     = local.npd["dependency_update"]
  disable_crd_hooks     = local.npd["disable_crd_hooks"]
  disable_webhooks      = local.npd["disable_webhooks"]
  render_subchart_notes = local.npd["render_subchart_notes"]
  replace               = local.npd["replace"]
  reset_values          = local.npd["reset_values"]
  reuse_values          = local.npd["reuse_values"]
  skip_crds             = local.npd["skip_crds"]
  verify                = local.npd["verify"]
  values = [
    local.values_npd,
    local.npd["extra_values"]
  ]
  namespace = kubernetes_namespace.node-problem-detector.*.metadata.0.name[count.index]
}