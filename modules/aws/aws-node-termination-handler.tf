locals {
  aws_node_termination_handler = merge(
    local.helm_defaults,
    {
      name                   = "aws-node-termination-handler"
      namespace              = "aws-node-termination-handler"
      chart                  = "aws-node-termination-handler"
      repository             = "https://aws.github.io/eks-charts"
      enabled                = false
      chart_version          = "0.9.5"
      version                = "v1.7.0"
      default_network_policy = true
    },
    var.aws_node_termination_handler
  )

  values_aws_node_termination_handler = <<VALUES
image:
  tag: ${local.aws_node_termination_handler["version"]}
priorityClassName: ${local.priority_class_ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}
deleteLocalData: true
nodeSelector:
 node.kubernetes.io/lifecycle: spot
VALUES

}

resource "kubernetes_namespace" "aws_node_termination_handler" {
  count = local.aws_node_termination_handler["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.aws_node_termination_handler["namespace"]
    }

    name = local.aws_node_termination_handler["namespace"]
  }
}

resource "helm_release" "aws_node_termination_handler" {
  count                 = local.aws_node_termination_handler["enabled"] ? 1 : 0
  repository            = local.aws_node_termination_handler["repository"]
  name                  = local.aws_node_termination_handler["name"]
  chart                 = local.aws_node_termination_handler["chart"]
  version               = local.aws_node_termination_handler["chart_version"]
  timeout               = local.aws_node_termination_handler["timeout"]
  force_update          = local.aws_node_termination_handler["force_update"]
  recreate_pods         = local.aws_node_termination_handler["recreate_pods"]
  wait                  = local.aws_node_termination_handler["wait"]
  atomic                = local.aws_node_termination_handler["atomic"]
  cleanup_on_fail       = local.aws_node_termination_handler["cleanup_on_fail"]
  dependency_update     = local.aws_node_termination_handler["dependency_update"]
  disable_crd_hooks     = local.aws_node_termination_handler["disable_crd_hooks"]
  disable_webhooks      = local.aws_node_termination_handler["disable_webhooks"]
  render_subchart_notes = local.aws_node_termination_handler["render_subchart_notes"]
  replace               = local.aws_node_termination_handler["replace"]
  reset_values          = local.aws_node_termination_handler["reset_values"]
  reuse_values          = local.aws_node_termination_handler["reuse_values"]
  skip_crds             = local.aws_node_termination_handler["skip_crds"]
  verify                = local.aws_node_termination_handler["verify"]
  values = [
    local.values_aws_node_termination_handler,
    local.aws_node_termination_handler["extra_values"]
  ]
  namespace = local.aws_node_termination_handler["namespace"]

  depends_on = [
    helm_release.prometheus_operator
  ]
}

resource "kubernetes_network_policy" "aws_node_termination_handler_default_deny" {
  count = local.aws_node_termination_handler["enabled"] && local.aws_node_termination_handler["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.aws_node_termination_handler.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.aws_node_termination_handler.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "aws_node_termination_handler_allow_namespace" {
  count = local.aws_node_termination_handler["enabled"] && local.aws_node_termination_handler["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.aws_node_termination_handler.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.aws_node_termination_handler.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.aws_node_termination_handler.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
