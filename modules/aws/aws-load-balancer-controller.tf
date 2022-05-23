locals {
  aws-load-balancer-controller = merge(
    local.helm_defaults,
    {
      name                      = local.helm_dependencies[index(local.helm_dependencies.*.name, "aws-load-balancer-controller")].name
      chart                     = local.helm_dependencies[index(local.helm_dependencies.*.name, "aws-load-balancer-controller")].name
      repository                = local.helm_dependencies[index(local.helm_dependencies.*.name, "aws-load-balancer-controller")].repository
      chart_version             = local.helm_dependencies[index(local.helm_dependencies.*.name, "aws-load-balancer-controller")].version
      namespace                 = "aws-load-balancer-controller"
      service_account_name      = "aws-load-balancer-controller"
      create_iam_resources_irsa = true
      enabled                   = false
      iam_policy_override       = null
      default_network_policy    = true
      allowed_cidrs             = ["0.0.0.0/0"]
      name_prefix               = "${var.cluster-name}-awslbc"
    },
    var.aws-load-balancer-controller
  )

  values_aws-load-balancer-controller = <<VALUES
clusterName: ${var.cluster-name}
region: ${data.aws_region.current.name}
serviceAccount:
  name: "${local.aws-load-balancer-controller["service_account_name"]}"
  annotations:
    eks.amazonaws.com/role-arn: "${local.aws-load-balancer-controller["enabled"] && local.aws-load-balancer-controller["create_iam_resources_irsa"] ? module.iam_assumable_role_aws-load-balancer-controller.iam_role_arn : ""}"
VALUES
}

module "iam_assumable_role_aws-load-balancer-controller" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> 5.0"
  create_role                   = local.aws-load-balancer-controller["enabled"] && local.aws-load-balancer-controller["create_iam_resources_irsa"]
  role_name                     = local.aws-load-balancer-controller["name_prefix"]
  provider_url                  = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns              = local.aws-load-balancer-controller["enabled"] && local.aws-load-balancer-controller["create_iam_resources_irsa"] ? [aws_iam_policy.aws-load-balancer-controller[0].arn] : []
  number_of_role_policy_arns    = 1
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.aws-load-balancer-controller["namespace"]}:${local.aws-load-balancer-controller["service_account_name"]}"]
  tags                          = local.tags
}

resource "aws_iam_policy" "aws-load-balancer-controller" {
  count  = local.aws-load-balancer-controller["enabled"] && local.aws-load-balancer-controller["create_iam_resources_irsa"] ? 1 : 0
  name   = local.aws-load-balancer-controller["name_prefix"]
  policy = local.aws-load-balancer-controller["iam_policy_override"] == null ? templatefile("${path.module}/iam/aws-load-balancer-controller.json", { arn-partition = var.arn-partition }) : local.aws-load-balancer-controller["iam_policy_override"]
  tags   = local.tags
}

resource "kubernetes_namespace" "aws-load-balancer-controller" {
  count = local.aws-load-balancer-controller["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.aws-load-balancer-controller["namespace"]
    }

    name = local.aws-load-balancer-controller["namespace"]
  }
}

resource "helm_release" "aws-load-balancer-controller" {
  count                 = local.aws-load-balancer-controller["enabled"] ? 1 : 0
  repository            = local.aws-load-balancer-controller["repository"]
  name                  = local.aws-load-balancer-controller["name"]
  chart                 = local.aws-load-balancer-controller["chart"]
  version               = local.aws-load-balancer-controller["chart_version"]
  timeout               = local.aws-load-balancer-controller["timeout"]
  force_update          = local.aws-load-balancer-controller["force_update"]
  recreate_pods         = local.aws-load-balancer-controller["recreate_pods"]
  wait                  = local.aws-load-balancer-controller["wait"]
  atomic                = local.aws-load-balancer-controller["atomic"]
  cleanup_on_fail       = local.aws-load-balancer-controller["cleanup_on_fail"]
  dependency_update     = local.aws-load-balancer-controller["dependency_update"]
  disable_crd_hooks     = local.aws-load-balancer-controller["disable_crd_hooks"]
  disable_webhooks      = local.aws-load-balancer-controller["disable_webhooks"]
  render_subchart_notes = local.aws-load-balancer-controller["render_subchart_notes"]
  replace               = local.aws-load-balancer-controller["replace"]
  reset_values          = local.aws-load-balancer-controller["reset_values"]
  reuse_values          = local.aws-load-balancer-controller["reuse_values"]
  skip_crds             = local.aws-load-balancer-controller["skip_crds"]
  verify                = local.aws-load-balancer-controller["verify"]
  values = [
    local.values_aws-load-balancer-controller,
    local.aws-load-balancer-controller["extra_values"]
  ]
  namespace = kubernetes_namespace.aws-load-balancer-controller.*.metadata.0.name[count.index]
}

resource "kubernetes_network_policy" "aws-load-balancer-controller_default_deny" {
  count = local.aws-load-balancer-controller["enabled"] && local.aws-load-balancer-controller["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.aws-load-balancer-controller.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.aws-load-balancer-controller.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "aws-load-balancer-controller_allow_namespace" {
  count = local.aws-load-balancer-controller["enabled"] && local.aws-load-balancer-controller["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.aws-load-balancer-controller.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.aws-load-balancer-controller.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.aws-load-balancer-controller.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "aws-load-balancer-controller_allow_control_plane" {
  count = local.aws-load-balancer-controller["enabled"] && local.aws-load-balancer-controller["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.aws-load-balancer-controller.*.metadata.0.name[count.index]}-allow-control-plane"
    namespace = kubernetes_namespace.aws-load-balancer-controller.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "app.kubernetes.io/name"
        operator = "In"
        values   = ["aws-load-balancer-controller"]
      }
    }

    ingress {
      ports {
        port     = "9443"
        protocol = "TCP"
      }

      dynamic "from" {
        for_each = local.aws-load-balancer-controller["allowed_cidrs"]
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
