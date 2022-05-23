locals {

  aws-for-fluent-bit = merge(
    local.helm_defaults,
    {
      name                             = local.helm_dependencies[index(local.helm_dependencies.*.name, "aws-for-fluent-bit")].name
      chart                            = local.helm_dependencies[index(local.helm_dependencies.*.name, "aws-for-fluent-bit")].name
      repository                       = local.helm_dependencies[index(local.helm_dependencies.*.name, "aws-for-fluent-bit")].repository
      chart_version                    = local.helm_dependencies[index(local.helm_dependencies.*.name, "aws-for-fluent-bit")].version
      namespace                        = "aws-for-fluent-bit"
      service_account_name             = "aws-for-fluent-bit"
      create_iam_resources_irsa        = true
      enabled                          = false
      iam_policy_override              = null
      default_network_policy           = true
      containers_log_retention_in_days = 180
      name_prefix                      = "${var.cluster-name}-aws-for-fluent-bit"
    },
    var.aws-for-fluent-bit
  )

  values_aws-for-fluent-bit = <<VALUES
firehose:
  enabled: false
kinesis:
  enabled: false
elasticsearch:
  enabled: false
cloudWatch:
  enabled: true
  region: "${data.aws_region.current.name}"
  logGroupName: "${local.aws-for-fluent-bit["enabled"] ? aws_cloudwatch_log_group.aws-for-fluent-bit[0].name : ""}"
  autoCreateGroup: false
serviceAccount:
  name: ${local.aws-for-fluent-bit["service_account_name"]}
  annotations:
    eks.amazonaws.com/role-arn: "${local.aws-for-fluent-bit["enabled"] && local.aws-for-fluent-bit["create_iam_resources_irsa"] ? module.iam_assumable_role_aws-for-fluent-bit.iam_role_arn : ""}"
tolerations:
- operator: Exists
priorityClassName: "${local.priority-class-ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}"
VALUES
}

module "iam_assumable_role_aws-for-fluent-bit" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> 5.0"
  create_role                   = local.aws-for-fluent-bit["enabled"] && local.aws-for-fluent-bit["create_iam_resources_irsa"]
  role_name                     = local.aws-for-fluent-bit["name_prefix"]
  provider_url                  = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns              = local.aws-for-fluent-bit["enabled"] && local.aws-for-fluent-bit["create_iam_resources_irsa"] ? [aws_iam_policy.aws-for-fluent-bit[0].arn] : []
  number_of_role_policy_arns    = 1
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.aws-for-fluent-bit["namespace"]}:${local.aws-for-fluent-bit["service_account_name"]}"]
  tags                          = local.tags
}

resource "aws_iam_policy" "aws-for-fluent-bit" {
  count  = local.aws-for-fluent-bit["enabled"] && local.aws-for-fluent-bit["create_iam_resources_irsa"] ? 1 : 0
  name   = local.aws-for-fluent-bit["name_prefix"]
  policy = local.aws-for-fluent-bit["iam_policy_override"] == null ? data.aws_iam_policy_document.aws-for-fluent-bit.json : local.aws-for-fluent-bit["iam_policy_override"]
  tags   = local.tags
}

data "aws_iam_policy_document" "aws-for-fluent-bit" {
  statement {
    effect = "Allow"

    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }
}

resource "aws_cloudwatch_log_group" "aws-for-fluent-bit" {
  count             = local.aws-for-fluent-bit["enabled"] ? 1 : 0
  name              = "/aws/eks/${var.cluster-name}/containers"
  retention_in_days = local.aws-for-fluent-bit["containers_log_retention_in_days"]
}

resource "kubernetes_namespace" "aws-for-fluent-bit" {
  count = local.aws-for-fluent-bit["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.aws-for-fluent-bit["namespace"]
    }

    name = local.aws-for-fluent-bit["namespace"]
  }
}

resource "helm_release" "aws-for-fluent-bit" {
  count                 = local.aws-for-fluent-bit["enabled"] ? 1 : 0
  repository            = local.aws-for-fluent-bit["repository"]
  name                  = local.aws-for-fluent-bit["name"]
  chart                 = local.aws-for-fluent-bit["chart"]
  version               = local.aws-for-fluent-bit["chart_version"]
  timeout               = local.aws-for-fluent-bit["timeout"]
  force_update          = local.aws-for-fluent-bit["force_update"]
  recreate_pods         = local.aws-for-fluent-bit["recreate_pods"]
  wait                  = local.aws-for-fluent-bit["wait"]
  atomic                = local.aws-for-fluent-bit["atomic"]
  cleanup_on_fail       = local.aws-for-fluent-bit["cleanup_on_fail"]
  dependency_update     = local.aws-for-fluent-bit["dependency_update"]
  disable_crd_hooks     = local.aws-for-fluent-bit["disable_crd_hooks"]
  disable_webhooks      = local.aws-for-fluent-bit["disable_webhooks"]
  render_subchart_notes = local.aws-for-fluent-bit["render_subchart_notes"]
  replace               = local.aws-for-fluent-bit["replace"]
  reset_values          = local.aws-for-fluent-bit["reset_values"]
  reuse_values          = local.aws-for-fluent-bit["reuse_values"]
  skip_crds             = local.aws-for-fluent-bit["skip_crds"]
  verify                = local.aws-for-fluent-bit["verify"]
  values = [
    local.values_aws-for-fluent-bit,
    local.aws-for-fluent-bit["extra_values"]
  ]
  namespace = kubernetes_namespace.aws-for-fluent-bit.*.metadata.0.name[count.index]
}

resource "kubernetes_network_policy" "aws-for-fluent-bit_default_deny" {
  count = local.aws-for-fluent-bit["enabled"] && local.aws-for-fluent-bit["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.aws-for-fluent-bit.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.aws-for-fluent-bit.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "aws-for-fluent-bit_allow_namespace" {
  count = local.aws-for-fluent-bit["enabled"] && local.aws-for-fluent-bit["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.aws-for-fluent-bit.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.aws-for-fluent-bit.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.aws-for-fluent-bit.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
