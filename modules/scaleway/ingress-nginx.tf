locals {

  ingress-nginx = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "ingress-nginx")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "ingress-nginx")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "ingress-nginx")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "ingress-nginx")].version
      namespace              = "ingress-nginx"
      enabled                = false
      default_network_policy = true
      ingress_cidrs          = ["0.0.0.0/0"]
      allowed_cidrs          = ["0.0.0.0/0"]
    },
    var.ingress-nginx
  )

  values_ingress-nginx_l4 = <<VALUES
controller:
  metrics:
    enabled: ${local.kube-prometheus-stack["enabled"] || local.victoria-metrics-k8s-stack["enabled"]}
    serviceMonitor:
      enabled: ${local.kube-prometheus-stack["enabled"] || local.victoria-metrics-k8s-stack["enabled"]}
  updateStrategy:
    type: RollingUpdate
  kind: "DaemonSet"
  service:
    annotations:
      service.beta.kubernetes.io/scw-loadbalancer-proxy-protocol-v2: 'true'
      service.beta.kubernetes.io/scw-loadbalancer-use-hostname: 'true'
  publishService:
    enabled: true
  config:
    use-proxy-protocol: "true"
  priorityClassName: ${local.priority-class-ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}
defaultBackend:
  replicaCount: 2
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
    local.values_ingress-nginx_l4,
    local.ingress-nginx["extra_values"],
  ]
  namespace = kubernetes_namespace.ingress-nginx.*.metadata.0.name[count.index]

  depends_on = [
    kubectl_manifest.prometheus-operator_crds
  ]
}

resource "kubernetes_network_policy" "ingress-nginx_default_deny" {
  count = local.ingress-nginx["enabled"] && local.ingress-nginx["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.ingress-nginx.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.ingress-nginx.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "ingress-nginx_allow_namespace" {
  count = local.ingress-nginx["enabled"] && local.ingress-nginx["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.ingress-nginx.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.ingress-nginx.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.ingress-nginx.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "ingress-nginx_allow_ingress" {
  count = local.ingress-nginx["enabled"] && local.ingress-nginx["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.ingress-nginx.*.metadata.0.name[count.index]}-allow-ingress"
    namespace = kubernetes_namespace.ingress-nginx.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "app.kubernetes.io/name"
        operator = "In"
        values   = ["ingress-nginx"]
      }
    }

    ingress {
      ports {
        port     = "80"
        protocol = "TCP"
      }
      ports {
        port     = "443"
        protocol = "TCP"
      }

      dynamic "from" {
        for_each = local.ingress-nginx["ingress_cidrs"]
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

resource "kubernetes_network_policy" "ingress-nginx_allow_monitoring" {
  count = local.ingress-nginx["enabled"] && local.ingress-nginx["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.ingress-nginx.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.ingress-nginx.*.metadata.0.name[count.index]
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

resource "kubernetes_network_policy" "ingress-nginx_allow_control_plane" {
  count = local.ingress-nginx["enabled"] && local.ingress-nginx["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.ingress-nginx.*.metadata.0.name[count.index]}-allow-control-plane"
    namespace = kubernetes_namespace.ingress-nginx.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "app.kubernetes.io/name"
        operator = "In"
        values   = ["ingress-nginx"]
      }
    }

    ingress {
      ports {
        port     = "8443"
        protocol = "TCP"
      }

      dynamic "from" {
        for_each = local.ingress-nginx["allowed_cidrs"]
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
