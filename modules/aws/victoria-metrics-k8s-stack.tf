locals {
  victoria-metrics-k8s-stack = merge(
    local.helm_defaults,
    {
      name                             = local.helm_dependencies[index(local.helm_dependencies.*.name, "victoria-metrics-k8s-stack")].name
      chart                            = local.helm_dependencies[index(local.helm_dependencies.*.name, "victoria-metrics-k8s-stack")].name
      repository                       = local.helm_dependencies[index(local.helm_dependencies.*.name, "victoria-metrics-k8s-stack")].repository
      chart_version                    = local.helm_dependencies[index(local.helm_dependencies.*.name, "victoria-metrics-k8s-stack")].version
      namespace                        = "monitoring"
      enabled                          = false
      allowed_cidrs                    = ["0.0.0.0/0"]
      install_prometheus_operator_crds = true
    },
    var.victoria-metrics-k8s-stack
  )

  values_victoria-metrics-k8s-stack = <<VALUES
kubeScheduler:
  enabled: false
kubeControllerManager:
  enabled: false
kubeEtcd:
  enabled: false
kubeProxy:
  enabled: false
grafana:
  adminPassword: ${join(",", random_string.grafana_password.*.result)}
prometheus-node-exporter:
  priorityClassName: ${local.priority-class-ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}
victoria-metrics-operator:
  createCRD: false
  operator:
    disable_prometheus_converter: false
    enable_converter_ownership: true
    useCustomConfigReloader: true
vmsingle:
  spec:
    extraArgs:
      maxLabelsPerTimeseries: "50"
vmagent:
  spec:
    externalLabels:
      cluster: ${var.cluster-name}
    serviceScrapeNamespaceSelector: {}
    podScrapeNamespaceSelector: {}
    podScrapeSelector: {}
    serviceScrapeSelector: {}
    nodeScrapeSelector: {}
    nodeScrapeNamespaceSelector: {}
    staticScrapeSelector: {}
    staticScrapeNamespaceSelector: {}
VALUES

}

resource "kubernetes_namespace" "victoria-metrics-k8s-stack" {
  count = local.victoria-metrics-k8s-stack["enabled"] ? 1 : 0

  metadata {
    labels = {
      name                               = local.victoria-metrics-k8s-stack["namespace"]
      "${local.labels_prefix}/component" = "monitoring"
    }

    name = local.victoria-metrics-k8s-stack["namespace"]
  }
}

resource "helm_release" "victoria-metrics-k8s-stack" {
  count                 = local.victoria-metrics-k8s-stack["enabled"] ? 1 : 0
  repository            = local.victoria-metrics-k8s-stack["repository"]
  name                  = local.victoria-metrics-k8s-stack["name"]
  chart                 = local.victoria-metrics-k8s-stack["chart"]
  version               = local.victoria-metrics-k8s-stack["chart_version"]
  timeout               = local.victoria-metrics-k8s-stack["timeout"]
  force_update          = local.victoria-metrics-k8s-stack["force_update"]
  recreate_pods         = local.victoria-metrics-k8s-stack["recreate_pods"]
  wait                  = local.victoria-metrics-k8s-stack["wait"]
  atomic                = local.victoria-metrics-k8s-stack["atomic"]
  cleanup_on_fail       = local.victoria-metrics-k8s-stack["cleanup_on_fail"]
  dependency_update     = local.victoria-metrics-k8s-stack["dependency_update"]
  disable_crd_hooks     = local.victoria-metrics-k8s-stack["disable_crd_hooks"]
  disable_webhooks      = local.victoria-metrics-k8s-stack["disable_webhooks"]
  render_subchart_notes = local.victoria-metrics-k8s-stack["render_subchart_notes"]
  replace               = local.victoria-metrics-k8s-stack["replace"]
  reset_values          = local.victoria-metrics-k8s-stack["reset_values"]
  reuse_values          = local.victoria-metrics-k8s-stack["reuse_values"]
  skip_crds             = local.victoria-metrics-k8s-stack["skip_crds"]
  verify                = local.victoria-metrics-k8s-stack["verify"]
  values = compact([
    local.values_victoria-metrics-k8s-stack,
    local.kong["enabled"] ? local.values_dashboard_kong : null,
    local.cert-manager["enabled"] ? local.values_dashboard_cert-manager : null,
    local.cluster-autoscaler["enabled"] ? local.values_dashboard_cluster-autoscaler : null,
    local.ingress-nginx["enabled"] ? local.values_dashboard_ingress-nginx : null,
    local.values_dashboard_node_exporter,
    local.victoria-metrics-k8s-stack["extra_values"]
  ])
  namespace = kubernetes_namespace.victoria-metrics-k8s-stack.*.metadata.0.name[count.index]

  depends_on = [
    helm_release.ingress-nginx,
  ]
}