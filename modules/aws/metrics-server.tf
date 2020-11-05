locals {
  metrics_server = merge(
    local.helm_defaults,
    {
      name                   = "metrics-server"
      namespace              = "metrics-server"
      chart                  = "metrics-server"
      repository             = "https://kubernetes-charts.storage.googleapis.com/"
      enabled                = false
      chart_version          = "2.11.1"
      version                = "v0.3.6"
      default_network_policy = true
      allowed_cidrs          = ["0.0.0.0/0"]
    },
    var.metrics_server
  )

  values_metrics_server = <<VALUES
image:
  tag: ${local.metrics_server["version"]}
args:
  - --logtostderr
  - --kubelet-preferred-address-types=InternalIP,ExternalIP
rbac:
  pspEnabled: true
priorityClassName: ${local.priority_class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
VALUES

}

resource "kubernetes_namespace" "metrics_server" {
  count = local.metrics_server["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.metrics_server["namespace"]
    }

    name = local.metrics_server["namespace"]
  }
}

resource "helm_release" "metrics_server" {
  count                 = local.metrics_server["enabled"] ? 1 : 0
  repository            = local.metrics_server["repository"]
  name                  = local.metrics_server["name"]
  chart                 = local.metrics_server["chart"]
  version               = local.metrics_server["chart_version"]
  timeout               = local.metrics_server["timeout"]
  force_update          = local.metrics_server["force_update"]
  recreate_pods         = local.metrics_server["recreate_pods"]
  wait                  = local.metrics_server["wait"]
  atomic                = local.metrics_server["atomic"]
  cleanup_on_fail       = local.metrics_server["cleanup_on_fail"]
  dependency_update     = local.metrics_server["dependency_update"]
  disable_crd_hooks     = local.metrics_server["disable_crd_hooks"]
  disable_webhooks      = local.metrics_server["disable_webhooks"]
  render_subchart_notes = local.metrics_server["render_subchart_notes"]
  replace               = local.metrics_server["replace"]
  reset_values          = local.metrics_server["reset_values"]
  reuse_values          = local.metrics_server["reuse_values"]
  skip_crds             = local.metrics_server["skip_crds"]
  verify                = local.metrics_server["verify"]
  values = [
    local.values_metrics_server,
    local.metrics_server["extra_values"]
  ]
  namespace = kubernetes_namespace.metrics_server.*.metadata.0.name[count.index]
}

resource "kubernetes_network_policy" "metrics_server_default_deny" {
  count = local.metrics_server["enabled"] && local.metrics_server["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.metrics_server.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.metrics_server.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "metrics_server_allow_namespace" {
  count = local.metrics_server["enabled"] && local.metrics_server["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.metrics_server.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.metrics_server.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.metrics_server.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "metrics_server_allow_control_plane" {
  count = local.metrics_server["enabled"] && local.metrics_server["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.metrics_server.*.metadata.0.name[count.index]}-allow-control-plane"
    namespace = kubernetes_namespace.metrics_server.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "app"
        operator = "In"
        values   = ["metrics-server"]
      }
    }

    ingress {
      ports {
        port     = "8443"
        protocol = "TCP"
      }

      dynamic "from" {
        for_each = local.metrics_server["allowed_cidrs"]
        content {
          ip_block {
            cidr = from.value
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

