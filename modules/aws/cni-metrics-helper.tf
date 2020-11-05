locals {
  cni_metrics_helper = merge(
    {
      create_iam_resources_irsa = true
      create_iam_resources_kiam = false
      enabled                   = false
      version                   = "v1.6.3"
      iam_policy_override       = ""
    },
    var.cni_metrics_helper
  )
}

module "iam_assumable_role_cni_metrics_helper" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v2.0"
  create_role                   = local.cni_metrics_helper["enabled"] && local.cni_metrics_helper["create_iam_resources_irsa"]
  role_name                     = "tf-eks-${var.cluster-name}-cni-metrics-helper-irsa"
  provider_url                  = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns              = local.cni_metrics_helper["enabled"] && local.cni_metrics_helper["create_iam_resources_irsa"] ? [aws_iam_policy.eks-cni-metrics-helper[0].arn] : []
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:cni-metrics-helper"]
}

resource "aws_iam_policy" "eks-cni-metrics-helper" {
  count  = local.cni_metrics_helper["enabled"] && (local.cni_metrics_helper["create_iam_resources_kiam"] || local.cni_metrics_helper["create_iam_resources_irsa"]) ? 1 : 0
  name   = "tf-eks-${var.cluster-name}-cni-metrics-helper"
  policy = local.cni_metrics_helper["iam_policy_override"] == "" ? data.aws_iam_policy_document.cni_metrics_helper.json : local.cni_metrics_helper["iam_policy_override"]
}

data "aws_iam_policy_document" "cni_metrics_helper" {
  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:PutMetricData",
      "ec2:DescribeTags"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "eks-cni-metrics-helper-kiam" {
  name  = "tf-eks-${var.cluster-name}-cni-metrics-helper-kiam"
  count = local.cni_metrics_helper["enabled"] && local.cni_metrics_helper["create_iam_resources_kiam"] ? 1 : 0

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

resource "aws_iam_role_policy_attachment" "eks-cni-metrics-helper-kiam" {
  count      = local.cni_metrics_helper["enabled"] && local.cni_metrics_helper["create_iam_resources_kiam"] ? 1 : 0
  role       = aws_iam_role.eks-cni-metrics-helper-kiam[count.index].name
  policy_arn = aws_iam_policy.eks-cni-metrics-helper[count.index].arn
}

resource "kubectl_manifest" "cni_metrics_helper" {
  count = local.cni_metrics_helper["enabled"] ? 1 : 0
  yaml_body = templatefile("${path.module}/templates/cni-metrics-helper.yaml", {
    cni_metrics_helper_role_arn_kiam = local.cni_metrics_helper["create_iam_resources_kiam"] ? aws_iam_role.eks-cni-metrics-helper-kiam[0].arn : ""
    cni_metrics_helper_role_arn_irsa = local.cni_metrics_helper["create_iam_resources_irsa"] ? module.iam_assumable_role_cni_metrics_helper.this_iam_role_arn : ""
    cni_metrics_helper_version       = local.cni_metrics_helper["version"]
  })
}
