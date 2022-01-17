locals {
  istio-operator = merge(
    local.helm_defaults,
    {
      name          = local.helm_dependencies[index(local.helm_dependencies.*.name, "istio-operator")].name
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "istio-operator")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "istio-operator")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "istio-operator")].version
      namespace     = "istio-system"
      enabled       = false
      version       = "1.7.4"
    },
    var.istio-operator
  )

  values_istio-operator = <<VALUES
hub: istio
tag: ${local.istio-operator["version"]}-distroless
VALUES
}

resource "kubernetes_namespace" "istio-operator" {
  count = local.istio-operator["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.istio-operator["namespace"]
    }

    name = local.istio-operator["namespace"]
  }
}

resource "helm_release" "istio-operator" {
  count                 = local.istio-operator["enabled"] ? 1 : 0
  repository            = local.istio-operator["repository"]
  name                  = local.istio-operator["name"]
  chart                 = local.istio-operator["chart"]
  version               = local.istio-operator["chart_version"]
  timeout               = local.istio-operator["timeout"]
  force_update          = local.istio-operator["force_update"]
  recreate_pods         = local.istio-operator["recreate_pods"]
  wait                  = local.istio-operator["wait"]
  atomic                = local.istio-operator["atomic"]
  cleanup_on_fail       = local.istio-operator["cleanup_on_fail"]
  dependency_update     = local.istio-operator["dependency_update"]
  disable_crd_hooks     = local.istio-operator["disable_crd_hooks"]
  disable_webhooks      = local.istio-operator["disable_webhooks"]
  render_subchart_notes = local.istio-operator["render_subchart_notes"]
  replace               = local.istio-operator["replace"]
  reset_values          = local.istio-operator["reset_values"]
  reuse_values          = local.istio-operator["reuse_values"]
  skip_crds             = local.istio-operator["skip_crds"]
  verify                = local.istio-operator["verify"]
  values = [
    local.values_istio-operator,
    local.istio-operator["extra_values"]
  ]
  namespace = kubernetes_namespace.istio-operator.*.metadata.0.name[count.index]
}