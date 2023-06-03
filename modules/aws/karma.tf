locals {
  karma = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "karma")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "karma")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "karma")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "karma")].version
      namespace              = "monitoring"
      create_ns              = false
      enabled                = false
      default_network_policy = true
    },
    var.karma
  )

  values_karma = <<VALUES
VALUES

}

resource "kubernetes_namespace" "karma" {
  count = local.karma["enabled"] && local.karma["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name                               = local.karma["namespace"]
      "${local.labels_prefix}/component" = "monitoring"
    }

    name = local.karma["namespace"]
  }
}

resource "helm_release" "karma" {
  count                 = local.karma["enabled"] ? 1 : 0
  repository            = local.karma["repository"]
  name                  = local.karma["name"]
  chart                 = local.karma["chart"]
  version               = local.karma["chart_version"]
  timeout               = local.karma["timeout"]
  force_update          = local.karma["force_update"]
  recreate_pods         = local.karma["recreate_pods"]
  wait                  = local.karma["wait"]
  atomic                = local.karma["atomic"]
  cleanup_on_fail       = local.karma["cleanup_on_fail"]
  dependency_update     = local.karma["dependency_update"]
  disable_crd_hooks     = local.karma["disable_crd_hooks"]
  disable_webhooks      = local.karma["disable_webhooks"]
  render_subchart_notes = local.karma["render_subchart_notes"]
  replace               = local.karma["replace"]
  reset_values          = local.karma["reset_values"]
  reuse_values          = local.karma["reuse_values"]
  skip_crds             = local.karma["skip_crds"]
  verify                = local.karma["verify"]
  values = [
    local.values_karma,
    local.karma["extra_values"]
  ]
  namespace = local.karma["create_ns"] ? kubernetes_namespace.karma.*.metadata.0.name[count.index] : local.karma["namespace"]

  depends_on = [
    kubectl_manifest.prometheus-operator_crds
  ]
}

resource "kubernetes_network_policy" "karma_default_deny" {
  count = local.karma["create_ns"] && local.karma["enabled"] && local.karma["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.karma.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.karma.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "karma_allow_namespace" {
  count = local.karma["create_ns"] && local.karma["enabled"] && local.karma["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.karma.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.karma.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.karma.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "karma_allow_ingress" {
  count = local.karma["enabled"] && local.karma["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${local.karma["create_ns"] ? kubernetes_namespace.karma.*.metadata.0.name[count.index] : local.karma["namespace"]}-allow-ingress-karma"
    namespace = local.karma["create_ns"] ? kubernetes_namespace.karma.*.metadata.0.name[count.index] : local.karma["namespace"]
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
