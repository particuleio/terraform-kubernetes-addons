locals {

  concourse = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "concourse")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "concourse")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "concourse")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "concourse")].version
      namespace              = "concourse"
      enabled                = false
      default_network_policy = true
      ingress_cidrs          = ["0.0.0.0/0"]
      allowed_cidrs          = ["0.0.0.0/0"]
    },
    var.concourse
  )

  values_concourse = <<VALUES
concourse:
  web:
    clusterName: local.concourse["name"]
    externalUrl: http://local.concourse["name"].particule.io
    ingress:
      enabled: local.ingress-nginx["enabled"]
      annotations:
        local.cert-manager["enabled"] ? cert-manager.io/cluster-issuer: letsencrypt : null
      hosts:
      - local.concourse["name"].particule.io
      tls:
      - hosts:
        - local.concourse["name"].particule.io
        secretName: local.concourse["name"].particule.io
    prometheus:
      enabled: local.kube-prometheus["enabled"]
      serviceMonitor:
        enabled: local.kube-prometheus["enabled"]
VALUES

}

resource "kubernetes_namespace" "concourse" {
  count = local.concourse["enabled"] ? 1 : 0

  metadata {
    labels = {
      name                               = local.concourse["namespace"]
      "${local.labels_prefix}/component" = "ci"
    }

    name = local.concourse["namespace"]
  }
}

resource "helm_release" "concourse" {
  count                 = local.concourse["enabled"] ? 1 : 0
  repository            = local.concourse["repository"]
  name                  = local.concourse["name"]
  chart                 = local.concourse["chart"]
  version               = local.concourse["chart_version"]
  timeout               = local.concourse["timeout"]
  force_update          = local.concourse["force_update"]
  recreate_pods         = local.concourse["recreate_pods"]
  wait                  = local.concourse["wait"]
  atomic                = local.concourse["atomic"]
  cleanup_on_fail       = local.concourse["cleanup_on_fail"]
  dependency_update     = local.concourse["dependency_update"]
  disable_crd_hooks     = local.concourse["disable_crd_hooks"]
  disable_webhooks      = local.concourse["disable_webhooks"]
  render_subchart_notes = local.concourse["render_subchart_notes"]
  replace               = local.concourse["replace"]
  reset_values          = local.concourse["reset_values"]
  reuse_values          = local.concourse["reuse_values"]
  skip_crds             = local.concourse["skip_crds"]
  verify                = local.concourse["verify"]
  values = [
    local.values_concourse,
    local.concourse["extra_values"],
  ]
  namespace = kubernetes_namespace.concourse.*.metadata.0.name[count.index]

  depends_on = [
    helm_release.kube-prometheus-stack
  ]
}

resource "kubernetes_network_policy" "concourse_default_deny" {
  count = local.concourse["enabled"] && local.concourse["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.concourse.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.concourse.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "concourse_allow_namespace" {
  count = local.concourse["enabled"] && local.concourse["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.concourse.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.concourse.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.concourse.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "concourse_allow_monitoring" {
  count = local.concourse["enabled"] && local.concourse["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.concourse.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.concourse.*.metadata.0.name[count.index]
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

