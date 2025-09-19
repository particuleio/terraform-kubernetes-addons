locals {
  grafana-mcp = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "grafana-mcp")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "grafana-mcp")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "grafana-mcp")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "grafana-mcp")].version
      namespace              = "telemetry"
      create_ns              = false
      enabled                = false
      default_network_policy = true
    },
    var.grafana-mcp
  )

  values_grafana-mcp = <<VALUES
    VALUES
}

resource "kubernetes_namespace" "grafana-mcp" {
  count = local.grafana-mcp["enabled"] && local.grafana-mcp["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name = local.grafana-mcp["namespace"]
    }

    name = local.grafana-mcp["namespace"]
  }
}

resource "helm_release" "grafana-mcp" {
  count                 = local.grafana-mcp["enabled"] ? 1 : 0
  repository            = local.grafana-mcp["repository"]
  name                  = local.grafana-mcp["name"]
  chart                 = local.grafana-mcp["chart"]
  version               = local.grafana-mcp["chart_version"]
  timeout               = local.grafana-mcp["timeout"]
  force_update          = local.grafana-mcp["force_update"]
  recreate_pods         = local.grafana-mcp["recreate_pods"]
  wait                  = local.grafana-mcp["wait"]
  atomic                = local.grafana-mcp["atomic"]
  cleanup_on_fail       = local.grafana-mcp["cleanup_on_fail"]
  dependency_update     = local.grafana-mcp["dependency_update"]
  disable_crd_hooks     = local.grafana-mcp["disable_crd_hooks"]
  disable_webhooks      = local.grafana-mcp["disable_webhooks"]
  render_subchart_notes = local.grafana-mcp["render_subchart_notes"]
  replace               = local.grafana-mcp["replace"]
  reset_values          = local.grafana-mcp["reset_values"]
  reuse_values          = local.grafana-mcp["reuse_values"]
  skip_crds             = local.grafana-mcp["skip_crds"]
  verify                = local.grafana-mcp["verify"]
  values = [
    local.values_grafana-mcp,
    local.grafana-mcp["extra_values"]
  ]
  namespace = local.grafana-mcp["create_ns"] ? kubernetes_namespace.grafana-mcp.*.metadata.0.name[count.index] : local.grafana-mcp["namespace"]
}

resource "kubernetes_network_policy" "grafana-mcp_default_deny" {
  count = local.grafana-mcp["create_ns"] && local.grafana-mcp["enabled"] && local.grafana-mcp["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.grafana-mcp.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.grafana-mcp.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "grafana-mcp_allow_namespace" {
  count = local.grafana-mcp["create_ns"] && local.grafana-mcp["enabled"] && local.grafana-mcp["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.grafana-mcp.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.grafana-mcp.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.grafana-mcp.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
