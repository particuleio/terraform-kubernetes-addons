locals {
  prometheus-blackbox-exporter = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "prometheus-blackbox-exporter")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "prometheus-blackbox-exporter")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "prometheus-blackbox-exporter")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "prometheus-blackbox-exporter")].version
      namespace              = "monitoring"
      create_ns              = false
      enabled                = false
      default_network_policy = true
    },
    var.prometheus-blackbox-exporter
  )

  values_prometheus-blackbox-exporter = <<VALUES
serviceMonitor:
  enabled: ${local.kube-prometheus-stack["enabled"] || local.victoria-metrics-k8s-stack["enabled"]}
VALUES

}

resource "kubernetes_namespace" "prometheus-blackbox-exporter" {
  count = local.prometheus-blackbox-exporter["enabled"] && local.prometheus-blackbox-exporter["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name                               = local.prometheus-blackbox-exporter["namespace"]
      "${local.labels_prefix}/component" = "monitoring"
    }

    name = local.prometheus-blackbox-exporter["namespace"]
  }
}

resource "helm_release" "prometheus-blackbox-exporter" {
  count                 = local.prometheus-blackbox-exporter["enabled"] ? 1 : 0
  repository            = local.prometheus-blackbox-exporter["repository"]
  name                  = local.prometheus-blackbox-exporter["name"]
  chart                 = local.prometheus-blackbox-exporter["chart"]
  version               = local.prometheus-blackbox-exporter["chart_version"]
  timeout               = local.prometheus-blackbox-exporter["timeout"]
  force_update          = local.prometheus-blackbox-exporter["force_update"]
  recreate_pods         = local.prometheus-blackbox-exporter["recreate_pods"]
  wait                  = local.prometheus-blackbox-exporter["wait"]
  atomic                = local.prometheus-blackbox-exporter["atomic"]
  cleanup_on_fail       = local.prometheus-blackbox-exporter["cleanup_on_fail"]
  dependency_update     = local.prometheus-blackbox-exporter["dependency_update"]
  disable_crd_hooks     = local.prometheus-blackbox-exporter["disable_crd_hooks"]
  disable_webhooks      = local.prometheus-blackbox-exporter["disable_webhooks"]
  render_subchart_notes = local.prometheus-blackbox-exporter["render_subchart_notes"]
  replace               = local.prometheus-blackbox-exporter["replace"]
  reset_values          = local.prometheus-blackbox-exporter["reset_values"]
  reuse_values          = local.prometheus-blackbox-exporter["reuse_values"]
  skip_crds             = local.prometheus-blackbox-exporter["skip_crds"]
  verify                = local.prometheus-blackbox-exporter["verify"]
  values = [
    local.values_prometheus-blackbox-exporter,
    local.prometheus-blackbox-exporter["extra_values"]
  ]
  namespace = local.prometheus-blackbox-exporter["create_ns"] ? kubernetes_namespace.prometheus-blackbox-exporter.*.metadata.0.name[count.index] : local.prometheus-blackbox-exporter["namespace"]

  depends_on = [
    kubectl_manifest.prometheus-operator_crds
  ]
}

resource "kubernetes_network_policy" "prometheus-blackbox-exporter_default_deny" {
  count = local.prometheus-blackbox-exporter["create_ns"] && local.prometheus-blackbox-exporter["enabled"] && local.prometheus-blackbox-exporter["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.prometheus-blackbox-exporter.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.prometheus-blackbox-exporter.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "prometheus-blackbox-exporter_allow_namespace" {
  count = local.prometheus-blackbox-exporter["create_ns"] && local.prometheus-blackbox-exporter["enabled"] && local.prometheus-blackbox-exporter["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.prometheus-blackbox-exporter.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.prometheus-blackbox-exporter.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.prometheus-blackbox-exporter.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
