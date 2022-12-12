locals {

  actions-runner-controller = merge(
    local.helm_defaults,
    {
      name                       = local.helm_dependencies[index(local.helm_dependencies.*.name, "actions-runner-controller")].name
      chart                      = local.helm_dependencies[index(local.helm_dependencies.*.name, "actions-runner-controller")].name
      repository                 = local.helm_dependencies[index(local.helm_dependencies.*.name, "actions-runner-controller")].repository
      chart_version              = local.helm_dependencies[index(local.helm_dependencies.*.name, "actions-runner-controller")].version
      namespace                  = "actions-runner-controller"
      enabled                    = false
      default_network_policy     = true
      ingress_cidrs              = ["0.0.0.0/0"]
      manage_crds                = true
      github_app_id              = ""
      github_app_installation_id = ""
      github_app_private_key     = ""
    },
    var.actions-runner-controller
  )

  values_actions-runner-controller = <<VALUES
authSecret:
  enabled: true
  name: github-app
VALUES
}

resource "kubernetes_namespace" "actions-runner-controller" {
  count = local.actions-runner-controller["enabled"] ? 1 : 0

  metadata {
    labels = {
      name                               = local.actions-runner-controller["namespace"]
      "${local.labels_prefix}/component" = "actions-runner-controller"
    }

    name = local.actions-runner-controller["namespace"]
  }
}

resource "kubernetes_secret" "actions-runner-controller-github-app" {
  count = local.actions-runner-controller["enabled"] ? 1 : 0
  metadata {
    name      = "github-app"
    namespace = local.actions-runner-controller["namespace"]
  }
  data = {
    github_app_id              = local.actions-runner-controller["github_app_id"]
    github_app_installation_id = local.actions-runner-controller["github_app_instalation_id"]
    github_app_private_key     = local.actions-runner-controller["github_app_private_key"]
  }
}

resource "helm_release" "actions-runner-controller" {
  count                 = local.actions-runner-controller["enabled"] ? 1 : 0
  repository            = local.actions-runner-controller["repository"]
  name                  = local.actions-runner-controller["name"]
  chart                 = local.actions-runner-controller["chart"]
  version               = local.actions-runner-controller["chart_version"]
  timeout               = local.actions-runner-controller["timeout"]
  force_update          = local.actions-runner-controller["force_update"]
  recreate_pods         = local.actions-runner-controller["recreate_pods"]
  wait                  = local.actions-runner-controller["wait"]
  atomic                = local.actions-runner-controller["atomic"]
  cleanup_on_fail       = local.actions-runner-controller["cleanup_on_fail"]
  dependency_update     = local.actions-runner-controller["dependency_update"]
  disable_crd_hooks     = local.actions-runner-controller["disable_crd_hooks"]
  disable_webhooks      = local.actions-runner-controller["disable_webhooks"]
  render_subchart_notes = local.actions-runner-controller["render_subchart_notes"]
  replace               = local.actions-runner-controller["replace"]
  reset_values          = local.actions-runner-controller["reset_values"]
  reuse_values          = local.actions-runner-controller["reuse_values"]
  skip_crds             = local.actions-runner-controller["skip_crds"]
  verify                = local.actions-runner-controller["verify"]
  values = [
    local.values_actions-runner-controller,
    local.actions-runner-controller["extra_values"]
  ]
  namespace = kubernetes_namespace.actions-runner-controller.*.metadata.0.name[count.index]

  depends_on = [
    kubectl_manifest.prometheus-operator_crds
  ]
}

resource "kubernetes_network_policy" "actions-runner-controller_default_deny" {
  count = local.actions-runner-controller["enabled"] && local.actions-runner-controller["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.actions-runner-controller.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.actions-runner-controller.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "actions-runner-controller_allow_namespace" {
  count = local.actions-runner-controller["enabled"] && local.actions-runner-controller["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.actions-runner-controller.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.actions-runner-controller.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.actions-runner-controller.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "actions-runner-controller_allow_ingress" {
  count = local.actions-runner-controller["enabled"] && local.actions-runner-controller["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.actions-runner-controller.*.metadata.0.name[count.index]}-allow-ingress"
    namespace = kubernetes_namespace.actions-runner-controller.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "app.kubernetes.io/name"
        operator = "In"
        values   = ["actions-runner-controller"]
      }
    }

    ingress {
      dynamic "from" {
        for_each = local.actions-runner-controller["ingress_cidrs"]
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

resource "kubernetes_network_policy" "actions-runner-controller_allow_monitoring" {
  count = local.actions-runner-controller["enabled"] && local.actions-runner-controller["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.actions-runner-controller.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.actions-runner-controller.*.metadata.0.name[count.index]
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
