locals {
  cni-metrics-helper = merge(
    {
      create_iam_resources_irsa = true
      enabled                   = false
      version                   = "v1.9.0"
      iam_policy_override       = null
      name_prefix               = "${var.cluster-name}-cni-metrics-helper"
    },
    var.cni-metrics-helper
  )
}

module "iam_assumable_role_cni-metrics-helper" {
  source             = "terraform-aws-modules/iam/aws//modules/iam-role"
  version            = "~> 6.0"
  create             = local.cni-metrics-helper["enabled"] && local.cni-metrics-helper["create_iam_resources_irsa"]
  name               = local.cni-metrics-helper["name_prefix"]
  enable_oidc        = true
  oidc_provider_urls = [replace(var.eks["cluster_oidc_issuer_url"], "https://", "")]
  policies           = local.cni-metrics-helper["enabled"] && local.cni-metrics-helper["create_iam_resources_irsa"] ? { cni-metrics-helper = aws_iam_policy.cni-metrics-helper[0].arn } : {}
  oidc_subjects      = ["system:serviceaccount:kube-system:cni-metrics-helper"]
  tags               = local.tags
}

resource "aws_iam_policy" "cni-metrics-helper" {
  count  = local.cni-metrics-helper["enabled"] && local.cni-metrics-helper["create_iam_resources_irsa"] ? 1 : 0
  name   = local.cni-metrics-helper["name_prefix"]
  policy = local.cni-metrics-helper["iam_policy_override"] == null ? data.aws_iam_policy_document.cni-metrics-helper.json : local.cni-metrics-helper["iam_policy_override"]
}

data "aws_iam_policy_document" "cni-metrics-helper" {
  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:PutMetricData",
      "ec2:DescribeTags"
    ]
    resources = ["*"]
  }
}

resource "kubectl_manifest" "cni-metrics-helper" {
  count = local.cni-metrics-helper["enabled"] ? 1 : 0
  yaml_body = templatefile("${path.module}/templates/cni-metrics-helper.yaml.tpl", {
    cni-metrics-helper_role_arn_irsa = local.cni-metrics-helper["create_iam_resources_irsa"] ? module.iam_assumable_role_cni-metrics-helper.arn : ""
    cni-metrics-helper_version       = local.cni-metrics-helper["version"]
  })
}
