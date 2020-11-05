locals {
  alb_ingress = merge(
    local.helm_defaults,
    {
      name                      = "aws-alb-ingress-controller"
      namespace                 = "aws-alb-ingress-controller"
      chart                     = "aws-alb-ingress-controller"
      repository                = "http://storage.googleapis.com/kubernetes-charts-incubator"
      service_account_name      = "aws-alb-ingress-controller"
      create_iam_resources_kiam = false
      create_iam_resources_irsa = true
      enabled                   = false
      chart_version             = "1.0.2"
      version                   = "v1.1.8"
      iam_policy_override       = ""
      default_network_policy    = true
    },
    var.alb_ingress
  )

  values_alb_ingress = <<VALUES
image:
  tag: "${local.alb_ingress["version"]}"
autoDiscoverAwsRegion: true
autoDiscoverAwsVpcID: true
clusterName: ${var.cluster-name}
rbac:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: "${local.alb_ingress["enabled"] && local.alb_ingress["create_iam_resources_irsa"] ? module.iam_assumable_role_alb_ingress.this_iam_role_arn : ""}"
VALUES
}

module "iam_assumable_role_alb_ingress" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v2.0"
  create_role                   = local.alb_ingress["enabled"] && local.alb_ingress["create_iam_resources_irsa"]
  role_name                     = "tf-eks-${var.cluster-name}-alb-ingress-irsa"
  provider_url                  = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns              = local.alb_ingress["enabled"] && local.alb_ingress["create_iam_resources_irsa"] ? [aws_iam_policy.eks-alb-ingress[0].arn] : []
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.alb_ingress["namespace"]}:${local.alb_ingress["service_account_name"]}"]
}

resource "aws_iam_policy" "eks-alb-ingress" {
  count  = local.alb_ingress["enabled"] && (local.alb_ingress["create_iam_resources_kiam"] || local.alb_ingress["create_iam_resources_irsa"]) ? 1 : 0
  name   = "tf-eks-${var.cluster-name}-alb-ingress"
  policy = local.alb_ingress["iam_policy_override"] == "" ? data.aws_iam_policy_document.alb_ingress.json : local.alb_ingress["iam_policy_override"]
}

data "aws_iam_policy_document" "alb_ingress" {

  statement {
    effect = "Allow"

    actions = [
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:GetCertificate"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcs",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:RevokeSecurityGroupIngress"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:SetWebACL"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "iam:CreateServiceLinkedRole",
      "iam:GetServerCertificate",
      "iam:ListServerCertificates"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "cognito-idp:DescribeUserPoolClient"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "waf-regional:GetWebACLForResource",
      "waf-regional:GetWebACL",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "tag:GetResources",
      "tag:TagResources"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "waf:GetWebACL"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "wafv2:GetWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "shield:DescribeProtection",
      "shield:GetSubscriptionState",
      "shield:DeleteProtection",
      "shield:CreateProtection",
      "shield:DescribeSubscription",
      "shield:ListProtections"
    ]

    resources = ["*"]
  }
}


resource "aws_iam_role" "eks-alb-ingress-kiam" {
  name  = "tf-eks-${var.cluster-name}-alb-ingress-kiam"
  count = local.alb_ingress["enabled"] && local.alb_ingress["create_iam_resources_kiam"] ? 1 : 0

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

resource "aws_iam_role_policy_attachment" "eks-alb-ingress-kiam" {
  count      = local.alb_ingress["enabled"] && local.alb_ingress["create_iam_resources_kiam"] ? 1 : 0
  role       = aws_iam_role.eks-alb-ingress-kiam[count.index].name
  policy_arn = aws_iam_policy.eks-alb-ingress[count.index].arn
}

resource "kubernetes_namespace" "alb_ingress" {
  count = local.alb_ingress["enabled"] ? 1 : 0

  metadata {
    annotations = {
      "iam.amazonaws.com/permitted" = "${local.alb_ingress["create_iam_resources_kiam"] ? aws_iam_role.eks-alb-ingress-kiam[0].arn : "^$"}"
    }

    labels = {
      name = local.alb_ingress["namespace"]
    }

    name = local.alb_ingress["namespace"]
  }
}

resource "helm_release" "alb_ingress" {
  count                 = local.alb_ingress["enabled"] ? 1 : 0
  repository            = local.alb_ingress["repository"]
  name                  = local.alb_ingress["name"]
  chart                 = local.alb_ingress["chart"]
  version               = local.alb_ingress["chart_version"]
  timeout               = local.alb_ingress["timeout"]
  force_update          = local.alb_ingress["force_update"]
  recreate_pods         = local.alb_ingress["recreate_pods"]
  wait                  = local.alb_ingress["wait"]
  atomic                = local.alb_ingress["atomic"]
  cleanup_on_fail       = local.alb_ingress["cleanup_on_fail"]
  dependency_update     = local.alb_ingress["dependency_update"]
  disable_crd_hooks     = local.alb_ingress["disable_crd_hooks"]
  disable_webhooks      = local.alb_ingress["disable_webhooks"]
  render_subchart_notes = local.alb_ingress["render_subchart_notes"]
  replace               = local.alb_ingress["replace"]
  reset_values          = local.alb_ingress["reset_values"]
  reuse_values          = local.alb_ingress["reuse_values"]
  skip_crds             = local.alb_ingress["skip_crds"]
  verify                = local.alb_ingress["verify"]
  values = [
    local.values_alb_ingress,
    local.alb_ingress["extra_values"]
  ]
  namespace = kubernetes_namespace.alb_ingress.*.metadata.0.name[count.index]

  depends_on = [
    helm_release.kiam,
    helm_release.prometheus_operator
  ]
}

resource "kubernetes_network_policy" "alb_ingress_default_deny" {
  count = local.alb_ingress["enabled"] && local.alb_ingress["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.alb_ingress.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.alb_ingress.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "alb_ingress_allow_namespace" {
  count = local.alb_ingress["enabled"] && local.alb_ingress["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.alb_ingress.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.alb_ingress.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.alb_ingress.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
