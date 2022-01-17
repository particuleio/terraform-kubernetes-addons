locals {
  prometheus-adapter = merge(
    local.helm_defaults,
    {
      name          = local.helm_dependencies[index(local.helm_dependencies.*.name, "prometheus-adapter")].name
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "prometheus-adapter")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "prometheus-adapter")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "prometheus-adapter")].version
      namespace     = "monitoring"
      create_ns     = false
      enabled       = false
    },
    var.prometheus-adapter
  )

  values_prometheus-adapter = <<VALUES
prometheus:
  url: http://${local.kube-prometheus-stack["name"]}-prometheus.${local.kube-prometheus-stack["namespace"]}.svc
VALUES

}

resource "kubernetes_namespace" "prometheus-adapter" {
  count = local.prometheus-adapter["enabled"] && local.prometheus-adapter["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name                               = local.prometheus-adapter["namespace"]
      "${local.labels_prefix}/component" = "monitoring"
    }

    name = local.prometheus-adapter["namespace"]
  }
}

resource "helm_release" "prometheus-adapter" {
  count                 = local.prometheus-adapter["enabled"] ? 1 : 0
  repository            = local.prometheus-adapter["repository"]
  name                  = local.prometheus-adapter["name"]
  chart                 = local.prometheus-adapter["chart"]
  version               = local.prometheus-adapter["chart_version"]
  timeout               = local.prometheus-adapter["timeout"]
  force_update          = local.prometheus-adapter["force_update"]
  recreate_pods         = local.prometheus-adapter["recreate_pods"]
  wait                  = local.prometheus-adapter["wait"]
  atomic                = local.prometheus-adapter["atomic"]
  cleanup_on_fail       = local.prometheus-adapter["cleanup_on_fail"]
  dependency_update     = local.prometheus-adapter["dependency_update"]
  disable_crd_hooks     = local.prometheus-adapter["disable_crd_hooks"]
  disable_webhooks      = local.prometheus-adapter["disable_webhooks"]
  render_subchart_notes = local.prometheus-adapter["render_subchart_notes"]
  replace               = local.prometheus-adapter["replace"]
  reset_values          = local.prometheus-adapter["reset_values"]
  reuse_values          = local.prometheus-adapter["reuse_values"]
  skip_crds             = local.prometheus-adapter["skip_crds"]
  verify                = local.prometheus-adapter["verify"]
  values = [
    local.values_prometheus-adapter,
    local.prometheus-adapter["extra_values"]
  ]
  namespace = local.prometheus-adapter["create_ns"] ? kubernetes_namespace.prometheus-adapter.*.metadata.0.name[count.index] : local.prometheus-adapter["namespace"]

  depends_on = [
    helm_release.kube-prometheus-stack
  ]
}