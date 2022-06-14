locals {

  flux = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "flux")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "flux")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "flux")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "flux")].version
      namespace              = "flux"
      service_account_name   = "flux"
      enabled                = false
      default_network_policy = true
    },
    var.flux
  )

  values_flux = <<VALUES
rbac:
  create: true
syncGarbageCollection:
  enabled: true
  dry: false
prometheus:
  enabled: ${local.kube-prometheus-stack["enabled"] || local.victoria-metrics-k8s-stack["enabled"]}
  serviceMonitor:
    create: ${local.kube-prometheus-stack["enabled"] || local.victoria-metrics-k8s-stack["enabled"]}
VALUES
}

resource "kubernetes_namespace" "flux" {
  count = local.flux["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.flux["namespace"]
    }

    name = local.flux["namespace"]
  }
}

resource "kubernetes_role" "flux" {
  count = local.flux["enabled"] ? 1 : 0

  metadata {
    name      = "flux-${kubernetes_namespace.flux.*.metadata.0.name[count.index]}"
    namespace = kubernetes_namespace.flux.*.metadata.0.name[count.index]
  }

  rule {
    api_groups = ["", "batch", "extensions", "apps"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_role_binding" "flux" {
  count = local.flux["enabled"] ? 1 : 0

  metadata {
    name      = "flux-${kubernetes_namespace.flux.*.metadata.0.name[count.index]}-binding"
    namespace = kubernetes_namespace.flux.*.metadata.0.name[count.index]
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.flux.*.metadata.0.name[count.index]
  }

  subject {
    kind      = "ServiceAccount"
    name      = "flux"
    namespace = "flux"
  }
}

resource "helm_release" "flux" {
  count                 = local.flux["enabled"] ? 1 : 0
  repository            = local.flux["repository"]
  name                  = local.flux["name"]
  chart                 = local.flux["chart"]
  version               = local.flux["chart_version"]
  timeout               = local.flux["timeout"]
  force_update          = local.flux["force_update"]
  recreate_pods         = local.flux["recreate_pods"]
  wait                  = local.flux["wait"]
  atomic                = local.flux["atomic"]
  cleanup_on_fail       = local.flux["cleanup_on_fail"]
  dependency_update     = local.flux["dependency_update"]
  disable_crd_hooks     = local.flux["disable_crd_hooks"]
  disable_webhooks      = local.flux["disable_webhooks"]
  render_subchart_notes = local.flux["render_subchart_notes"]
  replace               = local.flux["replace"]
  reset_values          = local.flux["reset_values"]
  reuse_values          = local.flux["reuse_values"]
  skip_crds             = local.flux["skip_crds"]
  verify                = local.flux["verify"]
  values = [
    local.values_flux,
    local.flux["extra_values"]
  ]
  namespace = kubernetes_namespace.flux.*.metadata.0.name[count.index]

  depends_on = [
    helm_release.kube-prometheus-stack
  ]
}

resource "kubernetes_network_policy" "flux_default_deny" {
  count = local.flux["enabled"] && local.flux["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.flux.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.flux.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "flux_allow_namespace" {
  count = local.flux["enabled"] && local.flux["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.flux.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.flux.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.flux.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "flux_allow_monitoring" {
  count = local.flux["enabled"] && local.flux["default_network_policy"] && local.kube-prometheus-stack["enabled"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.flux.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.flux.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      ports {
        port     = "3030"
        protocol = "TCP"
      }

      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.kube-prometheus-stack.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
