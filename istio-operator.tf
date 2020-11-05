locals {
  istio_operator = merge(
    local.helm_defaults,
    {
      name                   = "istio-operator"
      namespace              = "istio-system"
      chart                  = "istio-operator"
      repository             = "https://clusterfrak-dynamics.github.io/istio/"
      enabled                = false
      chart_version          = "1.7.0"
      version                = "1.7.0"
      default_network_policy = true
    },
    var.istio_operator
  )

  values_istio_operator = <<VALUES
hub: istio
tag: ${local.istio_operator["version"]}-distroless
VALUES
}

resource "kubernetes_namespace" "istio_operator" {
  count = local.istio_operator["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.istio_operator["namespace"]
    }

    name = local.istio_operator["namespace"]
  }
}

resource "helm_release" "istio_operator" {
  count                 = local.istio_operator["enabled"] ? 1 : 0
  repository            = local.istio_operator["repository"]
  name                  = local.istio_operator["name"]
  chart                 = local.istio_operator["chart"]
  version               = local.istio_operator["chart_version"]
  timeout               = local.istio_operator["timeout"]
  force_update          = local.istio_operator["force_update"]
  recreate_pods         = local.istio_operator["recreate_pods"]
  wait                  = local.istio_operator["wait"]
  atomic                = local.istio_operator["atomic"]
  cleanup_on_fail       = local.istio_operator["cleanup_on_fail"]
  dependency_update     = local.istio_operator["dependency_update"]
  disable_crd_hooks     = local.istio_operator["disable_crd_hooks"]
  disable_webhooks      = local.istio_operator["disable_webhooks"]
  render_subchart_notes = local.istio_operator["render_subchart_notes"]
  replace               = local.istio_operator["replace"]
  reset_values          = local.istio_operator["reset_values"]
  reuse_values          = local.istio_operator["reuse_values"]
  skip_crds             = local.istio_operator["skip_crds"]
  verify                = local.istio_operator["verify"]
  values = [
    local.values_istio_operator,
    local.istio_operator["extra_values"]
  ]
  namespace = kubernetes_namespace.istio_operator.*.metadata.0.name[count.index]
}

resource "kubernetes_network_policy" "istio_operator_default_deny" {
  count = local.istio_operator["enabled"] && local.istio_operator["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.istio_operator.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.istio_operator.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "istio_operator_allow_namespace" {
  count = local.istio_operator["enabled"] && local.istio_operator["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.istio_operator.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.istio_operator.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.istio_operator.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
