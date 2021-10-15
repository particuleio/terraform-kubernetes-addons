locals {
  rabbitmq = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "rabbitmq")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "rabbitmq")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "rabbitmq")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "rabbitmq")].version
      namespace              = "rabbitmq"
      create_ns              = false
      enabled                = false
      default_network_policy = true
    },
    var.rabbitmq
  )

  values_rabbitmq = <<VALUES
VALUES
}

resource "kubernetes_namespace" "rabbitmq" {
  count = local.rabbitmq["enabled"] && local.rabbitmq["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name                               = local.rabbitmq["namespace"]
      "${local.labels_prefix}/component" = "rabbitmq"
    }

    name = local.rabbitmq["namespace"]
  }
}

resource "helm_release" "rabbitmq" {
  count                 = local.rabbitmq["enabled"] ? 1 : 0
  repository            = local.rabbitmq["repository"]
  name                  = local.rabbitmq["name"]
  chart                 = local.rabbitmq["chart"]
  version               = local.rabbitmq["chart_version"]
  timeout               = local.rabbitmq["timeout"]
  force_update          = local.rabbitmq["force_update"]
  recreate_pods         = local.rabbitmq["recreate_pods"]
  wait                  = local.rabbitmq["wait"]
  atomic                = local.rabbitmq["atomic"]
  cleanup_on_fail       = local.rabbitmq["cleanup_on_fail"]
  dependency_update     = local.rabbitmq["dependency_update"]
  disable_crd_hooks     = local.rabbitmq["disable_crd_hooks"]
  disable_webhooks      = local.rabbitmq["disable_webhooks"]
  render_subchart_notes = local.rabbitmq["render_subchart_notes"]
  replace               = local.rabbitmq["replace"]
  reset_values          = local.rabbitmq["reset_values"]
  reuse_values          = local.rabbitmq["reuse_values"]
  skip_crds             = local.rabbitmq["skip_crds"]
  verify                = local.rabbitmq["verify"]
  values = [
    local.values_rabbitmq,
    local.rabbitmq["extra_values"]
  ]
  namespace = local.rabbitmq["create_ns"] ? kubernetes_namespace.rabbitmq.*.metadata.0.name[count.index] : local.rabbitmq["namespace"]

  depends_on = [
    helm_release.kube-prometheus-stack
  ]
}

resource "kubernetes_network_policy" "rabbitmq_default_deny" {
  count = local.rabbitmq["create_ns"] && local.rabbitmq["enabled"] && local.rabbitmq["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.rabbitmq.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.rabbitmq.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "rabbitmq_allow_namespace" {
  count = local.rabbitmq["create_ns"] && local.rabbitmq["enabled"] && local.rabbitmq["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.rabbitmq.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.rabbitmq.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.rabbitmq.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
