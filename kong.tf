locals {

  kong = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "kong")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "kong")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "kong")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "kong")].version
      namespace              = "kong"
      enabled                = false
      default_network_policy = true
      ingress_cidrs          = ["0.0.0.0/0"]
      manage_crds            = true
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

resource "kubernetes_network_policy" "kong_default_deny" {
  count = local.kong["enabled"] && local.kong["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.kong.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.kong.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "kong_allow_namespace" {
  count = local.kong["enabled"] && local.kong["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.kong.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.kong.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.kong.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "kong_allow_ingress" {
  count = local.kong["enabled"] && local.kong["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.kong.*.metadata.0.name[count.index]}-allow-ingress"
    namespace = kubernetes_namespace.kong.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "app.kubernetes.io/name"
        operator = "In"
        values   = ["kong"]
      }
    }

    ingress {
      ports {
        port     = "8000"
        protocol = "TCP"
      }
      ports {
        port     = "8443"
        protocol = "TCP"
      }

      dynamic "from" {
        for_each = local.kong["ingress_cidrs"]
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

resource "kubernetes_network_policy" "kong_allow_monitoring" {
  count = local.kong["enabled"] && local.kong["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.kong.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.kong.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      ports {
        port     = "metrics"
        protocol = "TCP"
      }

      from {
        namespace_selector {
          match_labels = {
            "${local.labels_prefix}/component" = "monitoring"
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
