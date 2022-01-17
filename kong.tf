locals {

  kong = merge(
    local.helm_defaults,
    {
      name          = local.helm_dependencies[index(local.helm_dependencies.*.name, "kong")].name
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "kong")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "kong")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "kong")].version
      namespace     = "kong"
      enabled       = false
      manage_crds   = true
    },
    var.kong
  )

  values_kong = <<VALUES
ingressController:
  enabled: true
  installCRDs: false
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
postgresql:
  enabled: false
env:
  database: "off"
admin:
  type: ClusterIP
podSecurityPolicy:
  enabled: true
autoscaling:
  enabled: true
replicaCount: 2
serviceMonitor:
  enabled: ${local.kube-prometheus-stack["enabled"] || local.victoria-metrics-k8s-stack["enabled"]}
resources:
  requests:
    cpu: 100m
    memory: 128Mi
VALUES
}

resource "kubernetes_namespace" "kong" {
  count = local.kong["enabled"] ? 1 : 0

  metadata {
    labels = {
      name                               = local.kong["namespace"]
      "${local.labels_prefix}/component" = "ingress"
    }

    name = local.kong["namespace"]
  }
}

resource "helm_release" "kong" {
  count                 = local.kong["enabled"] ? 1 : 0
  repository            = local.kong["repository"]
  name                  = local.kong["name"]
  chart                 = local.kong["chart"]
  version               = local.kong["chart_version"]
  timeout               = local.kong["timeout"]
  force_update          = local.kong["force_update"]
  recreate_pods         = local.kong["recreate_pods"]
  wait                  = local.kong["wait"]
  atomic                = local.kong["atomic"]
  cleanup_on_fail       = local.kong["cleanup_on_fail"]
  dependency_update     = local.kong["dependency_update"]
  disable_crd_hooks     = local.kong["disable_crd_hooks"]
  disable_webhooks      = local.kong["disable_webhooks"]
  render_subchart_notes = local.kong["render_subchart_notes"]
  replace               = local.kong["replace"]
  reset_values          = local.kong["reset_values"]
  reuse_values          = local.kong["reuse_values"]
  skip_crds             = local.kong["skip_crds"]
  verify                = local.kong["verify"]
  values = [
    local.values_kong,
    local.kong["extra_values"]
  ]
  namespace = kubernetes_namespace.kong.*.metadata.0.name[count.index]

  depends_on = [
    helm_release.kube-prometheus-stack
  ]
}