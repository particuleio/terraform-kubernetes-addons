locals {
  loki-stack = merge(
    local.helm_defaults,
    {
      name                   = "loki-stack"
      namespace              = "monitoring"
      chart                  = "loki-stack"
      repository             = "https://grafana.github.io/helm-charts"
      create_ns              = false
      enabled                = false
      chart_version          = "2.3.1"
      default_network_policy = true
    },
    var.loki-stack
  )

  values_loki-stack = <<VALUES
loki:
  priorityClassName: ${local.priority-class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
promtail:
    priorityClassName: ${local.priority-class-ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}
VALUES
}

resource "kubernetes_namespace" "loki-stack" {
  count = local.loki-stack["enabled"] && local.loki-stack["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name                               = local.loki-stack["namespace"]
      "${local.labels_prefix}/component" = "monitoring"
    }

    name = local.loki-stack["namespace"]
  }
}

resource "helm_release" "loki-stack" {
  count                 = local.loki-stack["enabled"] ? 1 : 0
  repository            = local.loki-stack["repository"]
  name                  = local.loki-stack["name"]
  chart                 = local.loki-stack["chart"]
  version               = local.loki-stack["chart_version"]
  timeout               = local.loki-stack["timeout"]
  force_update          = local.loki-stack["force_update"]
  recreate_pods         = local.loki-stack["recreate_pods"]
  wait                  = local.loki-stack["wait"]
  atomic                = local.loki-stack["atomic"]
  cleanup_on_fail       = local.loki-stack["cleanup_on_fail"]
  dependency_update     = local.loki-stack["dependency_update"]
  disable_crd_hooks     = local.loki-stack["disable_crd_hooks"]
  disable_webhooks      = local.loki-stack["disable_webhooks"]
  render_subchart_notes = local.loki-stack["render_subchart_notes"]
  replace               = local.loki-stack["replace"]
  reset_values          = local.loki-stack["reset_values"]
  reuse_values          = local.loki-stack["reuse_values"]
  skip_crds             = local.loki-stack["skip_crds"]
  verify                = local.loki-stack["verify"]
  values = [
    local.values_loki-stack,
    local.loki-stack["extra_values"]
  ]
  namespace = local.loki-stack["create_ns"] ? kubernetes_namespace.loki-stack.*.metadata.0.name[count.index] : local.loki-stack["namespace"]

  depends_on = [
    helm_release.kube-prometheus-stack
  ]
}

resource "kubernetes_network_policy" "loki-stack_default_deny" {
  count = local.loki-stack["create_ns"] && local.loki-stack["enabled"] && local.loki-stack["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.loki-stack.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.loki-stack.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "loki-stack_allow_namespace" {
  count = local.loki-stack["create_ns"] && local.loki-stack["enabled"] && local.loki-stack["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.loki-stack.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.loki-stack.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.loki-stack.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "loki-stack_allow_ingress" {
  count = local.loki-stack["create_ns"] && local.loki-stack["enabled"] && local.loki-stack["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.loki-stack.*.metadata.0.name[count.index]}-allow-ingress"
    namespace = kubernetes_namespace.loki-stack.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "${local.labels_prefix}/component" = "ingress"
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
