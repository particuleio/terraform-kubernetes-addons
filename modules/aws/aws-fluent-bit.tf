locals {

  aws_fluent_bit = merge(
    local.helm_defaults,
    {
      name                             = "aws-for-fluent-bit"
      namespace                        = "aws-for-fluent-bit"
      chart                            = "aws-for-fluent-bit"
      repository                       = "https://clusterfrak-dynamics.github.io/eks-charts"
      service_account_name             = "aws-for-fluent-bit"
      create_iam_resources_kiam        = false
      create_iam_resources_irsa        = true
      enabled                          = false
      chart_version                    = "0.1.3"
      version                          = "2.3.0"
      iam_policy_override              = ""
      default_network_policy           = true
      containers_log_retention_in_days = 180
    },
    var.aws_fluent_bit
  )

  values_aws_fluent_bit = <<VALUES
firehose:
  enabled: false
kinesis:
  enabled: false
cloudWatch:
  enabled: true
  region: "${data.aws_region.current.name}"
  logGroupName: "${local.aws_fluent_bit["enabled"] ? aws_cloudwatch_log_group.eks-aws-fluent-bit-log-group[0].name : ""}"
  autoCreateGroup: false
image:
  tag: ${local.aws_fluent_bit["version"]}
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: "${local.aws_fluent_bit["enabled"] && local.aws_fluent_bit["create_iam_resources_irsa"] ? module.iam_assumable_role_aws_fluent_bit.this_iam_role_arn : ""}"
tolerations:
- operator: Exists
priorityClassName: "${local.priority_class_ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}"
VALUES
}

module "iam_assumable_role_aws_fluent_bit" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v2.0"
  create_role                   = local.aws_fluent_bit["enabled"] && local.aws_fluent_bit["create_iam_resources_irsa"]
  role_name                     = "tf-eks-${var.cluster-name}-aws-fluent-bit-irsa"
  provider_url                  = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns              = local.aws_fluent_bit["enabled"] && local.aws_fluent_bit["create_iam_resources_irsa"] ? [aws_iam_policy.eks-aws-fluent-bit[0].arn] : []
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.aws_fluent_bit["namespace"]}:${local.aws_fluent_bit["service_account_name"]}"]
}

resource "aws_iam_policy" "eks-aws-fluent-bit" {
  count  = local.aws_fluent_bit["enabled"] && (local.aws_fluent_bit["create_iam_resources_kiam"] || local.aws_fluent_bit["create_iam_resources_irsa"]) ? 1 : 0
  name   = "tf-eks-${var.cluster-name}-aws-fluent-bit"
  policy = local.aws_fluent_bit["iam_policy_override"] == "" ? data.aws_iam_policy_document.aws_fluent_bit.json : local.aws_fluent_bit["iam_policy_override"]
}

data "aws_iam_policy_document" "aws_fluent_bit" {
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

resource "aws_cloudwatch_log_group" "eks-aws-fluent-bit-log-group" {
  count             = local.aws_fluent_bit["enabled"] ? 1 : 0
  name              = "/aws/eks/${var.cluster-name}/containers"
  retention_in_days = local.aws_fluent_bit["containers_log_retention_in_days"]
}

resource "aws_iam_role" "eks-aws-fluent-bit-kiam" {
  name  = "tf-eks-${var.cluster-name}-aws-fluent-bit-kiam"
  count = local.aws_fluent_bit["enabled"] && local.aws_fluent_bit["create_iam_resources_kiam"] ? 1 : 0

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_role.eks-kiam-server-role[count.index].arn}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

}

resource "aws_iam_role_policy_attachment" "eks-aws-fluent-bit-kiam" {
  count      = local.aws_fluent_bit["enabled"] && local.aws_fluent_bit["create_iam_resources_kiam"] ? 1 : 0
  role       = aws_iam_role.eks-aws-fluent-bit-kiam[count.index].name
  policy_arn = aws_iam_policy.eks-aws-fluent-bit[count.index].arn
}

resource "kubernetes_namespace" "aws_fluent_bit" {
  count = local.aws_fluent_bit["enabled"] ? 1 : 0

  metadata {
    annotations = {
      "iam.amazonaws.com/permitted" = "${local.aws_fluent_bit["create_iam_resources_kiam"] ? aws_iam_role.eks-aws-fluent-bit-kiam[0].arn : "^$"}"
    }

    labels = {
      name = local.aws_fluent_bit["namespace"]
    }

    name = local.aws_fluent_bit["namespace"]
  }
}

resource "helm_release" "aws_fluent_bit" {
  count                 = local.aws_fluent_bit["enabled"] ? 1 : 0
  repository            = local.aws_fluent_bit["repository"]
  name                  = local.aws_fluent_bit["name"]
  chart                 = local.aws_fluent_bit["chart"]
  version               = local.aws_fluent_bit["chart_version"]
  timeout               = local.aws_fluent_bit["timeout"]
  force_update          = local.aws_fluent_bit["force_update"]
  recreate_pods         = local.aws_fluent_bit["recreate_pods"]
  wait                  = local.aws_fluent_bit["wait"]
  atomic                = local.aws_fluent_bit["atomic"]
  cleanup_on_fail       = local.aws_fluent_bit["cleanup_on_fail"]
  dependency_update     = local.aws_fluent_bit["dependency_update"]
  disable_crd_hooks     = local.aws_fluent_bit["disable_crd_hooks"]
  disable_webhooks      = local.aws_fluent_bit["disable_webhooks"]
  render_subchart_notes = local.aws_fluent_bit["render_subchart_notes"]
  replace               = local.aws_fluent_bit["replace"]
  reset_values          = local.aws_fluent_bit["reset_values"]
  reuse_values          = local.aws_fluent_bit["reuse_values"]
  skip_crds             = local.aws_fluent_bit["skip_crds"]
  verify                = local.aws_fluent_bit["verify"]
  values = [
    local.values_aws_fluent_bit,
    local.aws_fluent_bit["extra_values"]
  ]
  namespace = kubernetes_namespace.aws_fluent_bit.*.metadata.0.name[count.index]

  depends_on = [
    helm_release.kiam
  ]
}

resource "kubernetes_network_policy" "aws_fluent_bit_default_deny" {
  count = local.aws_fluent_bit["enabled"] && local.aws_fluent_bit["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.aws_fluent_bit.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.aws_fluent_bit.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "aws_fluent_bit_allow_namespace" {
  count = local.aws_fluent_bit["enabled"] && local.aws_fluent_bit["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.aws_fluent_bit.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.aws_fluent_bit.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.aws_fluent_bit.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

