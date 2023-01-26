locals {
  aws-node-termination-handler = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies[0].name, "aws-node-termination-handler")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies[0].name, "aws-node-termination-handler")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies[0].name, "aws-node-termination-handler")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies[0].name, "aws-node-termination-handler")].version
      namespace              = "aws-node-termination-handler"
      enabled                = false
      default_network_policy = true
    },
    var.aws-node-termination-handler
  )

  values_aws-node-termination-handler = <<VALUES
priorityClassName: ${local.priority-class-ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}
deleteLocalData: true
VALUES

}

resource "kubernetes_namespace" "aws-node-termination-handler" {
  count = local.aws-node-termination-handler["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.aws-node-termination-handler["namespace"]
    }

    name = local.aws-node-termination-handler["namespace"]
  }
}

resource "helm_release" "aws-node-termination-handler" {
  count                 = local.aws-node-termination-handler["enabled"] ? 1 : 0
  repository            = local.aws-node-termination-handler["repository"]
  name                  = local.aws-node-termination-handler["name"]
  chart                 = local.aws-node-termination-handler["chart"]
  version               = local.aws-node-termination-handler["chart_version"]
  timeout               = local.aws-node-termination-handler["timeout"]
  force_update          = local.aws-node-termination-handler["force_update"]
  recreate_pods         = local.aws-node-termination-handler["recreate_pods"]
  wait                  = local.aws-node-termination-handler["wait"]
  atomic                = local.aws-node-termination-handler["atomic"]
  cleanup_on_fail       = local.aws-node-termination-handler["cleanup_on_fail"]
  dependency_update     = local.aws-node-termination-handler["dependency_update"]
  disable_crd_hooks     = local.aws-node-termination-handler["disable_crd_hooks"]
  disable_webhooks      = local.aws-node-termination-handler["disable_webhooks"]
  render_subchart_notes = local.aws-node-termination-handler["render_subchart_notes"]
  replace               = local.aws-node-termination-handler["replace"]
  reset_values          = local.aws-node-termination-handler["reset_values"]
  reuse_values          = local.aws-node-termination-handler["reuse_values"]
  skip_crds             = local.aws-node-termination-handler["skip_crds"]
  verify                = local.aws-node-termination-handler["verify"]
  values = [
    local.values_aws-node-termination-handler,
    local.aws-node-termination-handler["extra_values"]
  ]
  namespace = local.aws-node-termination-handler["namespace"]
}

resource "kubernetes_network_policy" "aws-node-termination-handler_default_deny" {
  count = local.aws-node-termination-handler["enabled"] && local.aws-node-termination-handler["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.aws-node-termination-handler[0].metadata[0].name[count.index]}-default-deny"
    namespace = kubernetes_namespace.aws-node-termination-handler[0].metadata[0].name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "aws-node-termination-handler_allow_namespace" {
  count = local.aws-node-termination-handler["enabled"] && local.aws-node-termination-handler["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.aws-node-termination-handler[0].metadata[0].name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.aws-node-termination-handler[0].metadata[0].name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.aws-node-termination-handler[0].metadata[0].name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
