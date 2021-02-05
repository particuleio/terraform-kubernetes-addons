locals {
  prometheus-adapter = merge(
    local.helm_defaults,
    {
      name                   = "prometheus-adapter"
      namespace              = "monitoring"
      chart                  = "prometheus-adapter"
      repository             = "https://prometheus-community.github.io/helm-charts"
      create_ns              = false
      enabled                = false
      chart_version          = "2.11.1"
      version                = "v0.8.3"
      default_network_policy = true
    },
    var.prometheus-adapter
  )

  values_prometheus-adapter = <<VALUES
image:
  tag: ${local.prometheus-adapter["version"]}
prometheus:
  url: http://"${local.kube-prometheus-stack["name"]}-prometheus:9090".${local.kube-prometheus-stack["namespace"]}.svc
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

resource "kubernetes_network_policy" "prometheus-adapter_default_deny" {
  count = local.prometheus-adapter["create_ns"] && local.prometheus-adapter["enabled"] && local.prometheus-adapter["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.prometheus-adapter.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.prometheus-adapter.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "prometheus-adapter_allow_namespace" {
  count = local.prometheus-adapter["create_ns"] && local.prometheus-adapter["enabled"] && local.prometheus-adapter["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.prometheus-adapter.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.prometheus-adapter.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.prometheus-adapter.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
