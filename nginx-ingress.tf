locals {

  nginx_ingress = merge(
    local.helm_defaults,
    {
      name                   = "ingress-nginx"
      namespace              = "ingress-nginx"
      chart                  = "ingress-nginx"
      repository             = "https://kubernetes.github.io/ingress-nginx"
      use_nlb                = false
      use_l7                 = false
      enabled                = false
      default_network_policy = true
      ingress_cidr           = "0.0.0.0/0"
      chart_version          = "2.15.0"
      version                = "0.35.0"
      allowed_cidrs          = ["0.0.0.0/0"]
    },
    var.nginx_ingress
  )

  values_nginx_ingress_l4 = <<VALUES
controller:
  metrics:
    enabled: ${local.prometheus_operator["enabled"]}
    serviceMonitor:
      enabled: ${local.prometheus_operator["enabled"]}
  image:
    tag: ${local.nginx_ingress["version"]}
  updateStrategy:
    type: RollingUpdate
  kind: "DaemonSet"
  service:
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
      service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: "3600"
  publishService:
    enabled: true
  config:
    use-proxy-protocol: "true"
  priorityClassName: ${local.priority_class_ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}
defaultBackend:
  replicaCount: 2
podSecurityPolicy:
  enabled: true
VALUES

  values_nginx_ingress_nlb = <<VALUES
controller:
  metrics:
    enabled: ${local.prometheus_operator["enabled"]}
    serviceMonitor:
      enabled: ${local.prometheus_operator["enabled"]}
  image:
    tag: ${local.nginx_ingress["version"]}
  updateStrategy:
    type: RollingUpdate
  kind: "DaemonSet"
  service:
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: nlb
    externalTrafficPolicy: "Local"
  publishService:
    enabled: true
  config:
    use-proxy-protocol: "false"
  priorityClassName: ${local.priority_class_ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}
defaultBackend:
  replicaCount: 2
podSecurityPolicy:
  enabled: true
VALUES

  values_nginx_ingress_l7 = <<VALUES
controller:
  metrics:
    enabled: ${local.prometheus_operator["enabled"]}
    serviceMonitor:
      enabled: ${local.prometheus_operator["enabled"]}
  image:
    tag: ${local.nginx_ingress["version"]}
  updateStrategy:
    type: RollingUpdate
  kind: "DaemonSet"
  service:
    targetPorts:
      http: http
      https: http
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "http"
      service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "https"
      service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: "3600"
    externalTrafficPolicy: "Cluster"
  publishService:
    enabled: true
  config:
    use-proxy-protocol: "false"
    use-forwarded-headers: "true"
    proxy-real-ip-cidr: "0.0.0.0/0"
  priorityClassName: ${local.priority_class_ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}
defaultBackend:
  replicaCount: 2
podSecurityPolicy:
  enabled: true
VALUES

}

resource "kubernetes_namespace" "nginx_ingress" {
  count = local.nginx_ingress["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.nginx_ingress["namespace"]
    }

    name = local.nginx_ingress["namespace"]
  }
}

resource "helm_release" "nginx_ingress" {
  count                 = local.nginx_ingress["enabled"] ? 1 : 0
  repository            = local.nginx_ingress["repository"]
  name                  = local.nginx_ingress["name"]
  chart                 = local.nginx_ingress["chart"]
  version               = local.nginx_ingress["chart_version"]
  timeout               = local.nginx_ingress["timeout"]
  force_update          = local.nginx_ingress["force_update"]
  recreate_pods         = local.nginx_ingress["recreate_pods"]
  wait                  = local.nginx_ingress["wait"]
  atomic                = local.nginx_ingress["atomic"]
  cleanup_on_fail       = local.nginx_ingress["cleanup_on_fail"]
  dependency_update     = local.nginx_ingress["dependency_update"]
  disable_crd_hooks     = local.nginx_ingress["disable_crd_hooks"]
  disable_webhooks      = local.nginx_ingress["disable_webhooks"]
  render_subchart_notes = local.nginx_ingress["render_subchart_notes"]
  replace               = local.nginx_ingress["replace"]
  reset_values          = local.nginx_ingress["reset_values"]
  reuse_values          = local.nginx_ingress["reuse_values"]
  skip_crds             = local.nginx_ingress["skip_crds"]
  verify                = local.nginx_ingress["verify"]
  values = [
    local.nginx_ingress["use_nlb"] ? local.values_nginx_ingress_nlb : local.nginx_ingress["use_l7"] ? local.values_nginx_ingress_l7 : local.values_nginx_ingress_l4,
    local.nginx_ingress["extra_values"],
  ]
  namespace = kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]

  depends_on = [
    helm_release.prometheus_operator
  ]
}

resource "kubernetes_network_policy" "nginx_ingress_default_deny" {
  count = local.nginx_ingress["enabled"] && local.nginx_ingress["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "nginx_ingress_allow_namespace" {
  count = local.nginx_ingress["enabled"] && local.nginx_ingress["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "nginx_ingress_allow_ingress" {
  count = local.nginx_ingress["enabled"] && local.nginx_ingress["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]}-allow-ingress"
    namespace = kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]
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

      from {
        ip_block {
          cidr = local.nginx_ingress["ingress_cidr"]
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "nginx_ingress_allow_monitoring" {
  count = local.nginx_ingress["enabled"] && local.nginx_ingress["default_network_policy"] && local.prometheus_operator["enabled"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]
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
            name = kubernetes_namespace.prometheus_operator.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "nginx_ingress_allow_control_plane" {
  count = local.nginx_ingress["enabled"] && local.nginx_ingress["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]}-allow-control-plane"
    namespace = kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]
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
        for_each = local.nginx_ingress["allowed_cidrs"]
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
