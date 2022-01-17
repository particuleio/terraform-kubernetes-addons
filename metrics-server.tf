locals {
  metrics-server = merge(
    local.helm_defaults,
    {
      name          = local.helm_dependencies[index(local.helm_dependencies.*.name, "metrics-server")].name
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "metrics-server")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "metrics-server")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "metrics-server")].version
      namespace     = "metrics-server"
      enabled       = false
      allowed_cidrs = ["0.0.0.0/0"]
    },
    var.metrics-server
  )

  values_metrics-server = <<VALUES
apiService:
  create: true
priorityClassName: ${local.priority-class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
VALUES

}

resource "kubernetes_namespace" "metrics-server" {
  count = local.metrics-server["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.metrics-server["namespace"]
    }

    name = local.metrics-server["namespace"]
  }
}

resource "helm_release" "metrics-server" {
  count                 = local.metrics-server["enabled"] ? 1 : 0
  repository            = local.metrics-server["repository"]
  name                  = local.metrics-server["name"]
  chart                 = local.metrics-server["chart"]
  version               = local.metrics-server["chart_version"]
  timeout               = local.metrics-server["timeout"]
  force_update          = local.metrics-server["force_update"]
  recreate_pods         = local.metrics-server["recreate_pods"]
  wait                  = local.metrics-server["wait"]
  atomic                = local.metrics-server["atomic"]
  cleanup_on_fail       = local.metrics-server["cleanup_on_fail"]
  dependency_update     = local.metrics-server["dependency_update"]
  disable_crd_hooks     = local.metrics-server["disable_crd_hooks"]
  disable_webhooks      = local.metrics-server["disable_webhooks"]
  render_subchart_notes = local.metrics-server["render_subchart_notes"]
  replace               = local.metrics-server["replace"]
  reset_values          = local.metrics-server["reset_values"]
  reuse_values          = local.metrics-server["reuse_values"]
  skip_crds             = local.metrics-server["skip_crds"]
  verify                = local.metrics-server["verify"]
  values = [
    local.values_metrics-server,
    local.metrics-server["extra_values"]
  ]
  namespace = kubernetes_namespace.metrics-server.*.metadata.0.name[count.index]
}