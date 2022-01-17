locals {

  ingress-nginx = merge(
    local.helm_defaults,
    {
      name          = local.helm_dependencies[index(local.helm_dependencies.*.name, "ingress-nginx")].name
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "ingress-nginx")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "ingress-nginx")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "ingress-nginx")].version
      namespace     = "ingress-nginx"
      enabled       = false
    },
    var.ingress-nginx
  )

  values_ingress-nginx = <<VALUES
controller:
  metrics:
    enabled: ${local.kube-prometheus-stack["enabled"] || local.victoria-metrics-k8s-stack["enabled"]}
    serviceMonitor:
      enabled: ${local.kube-prometheus-stack["enabled"] || local.victoria-metrics-k8s-stack["enabled"]}
  updateStrategy:
    type: RollingUpdate
  kind: "DaemonSet"
  publishService:
    enabled: true
  priorityClassName: ${local.priority-class-ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}
podSecurityPolicy:
  enabled: false
  admissionWebhooks:
    patch:
      podAnnotations:
        linkerd.io/inject: disabled
VALUES

}

resource "kubernetes_namespace" "ingress-nginx" {
  count = local.ingress-nginx["enabled"] ? 1 : 0

  metadata {
    labels = {
      name                               = local.ingress-nginx["namespace"]
      "${local.labels_prefix}/component" = "ingress"
    }

    name = local.ingress-nginx["namespace"]
  }
}

resource "helm_release" "ingress-nginx" {
  count                 = local.ingress-nginx["enabled"] ? 1 : 0
  repository            = local.ingress-nginx["repository"]
  name                  = local.ingress-nginx["name"]
  chart                 = local.ingress-nginx["chart"]
  version               = local.ingress-nginx["chart_version"]
  timeout               = local.ingress-nginx["timeout"]
  force_update          = local.ingress-nginx["force_update"]
  recreate_pods         = local.ingress-nginx["recreate_pods"]
  wait                  = local.ingress-nginx["wait"]
  atomic                = local.ingress-nginx["atomic"]
  cleanup_on_fail       = local.ingress-nginx["cleanup_on_fail"]
  dependency_update     = local.ingress-nginx["dependency_update"]
  disable_crd_hooks     = local.ingress-nginx["disable_crd_hooks"]
  disable_webhooks      = local.ingress-nginx["disable_webhooks"]
  render_subchart_notes = local.ingress-nginx["render_subchart_notes"]
  replace               = local.ingress-nginx["replace"]
  reset_values          = local.ingress-nginx["reset_values"]
  reuse_values          = local.ingress-nginx["reuse_values"]
  skip_crds             = local.ingress-nginx["skip_crds"]
  verify                = local.ingress-nginx["verify"]
  values = [
    local.values_ingress-nginx,
    local.ingress-nginx["extra_values"],
  ]
  namespace = kubernetes_namespace.ingress-nginx.*.metadata.0.name[count.index]

  depends_on = [
    kubectl_manifest.prometheus-operator_crds
  ]
}
