locals {
  cluster_autoscaler = merge(
    local.helm_defaults,
    {
      name                      = "cluster-autoscaler"
      namespace                 = "cluster-autoscaler"
      chart                     = "cluster-autoscaler-chart"
      repository                = "https://kubernetes.github.io/autoscaler"
      service_account_name      = "cluster-autoscaler"
      create_iam_resources_kiam = false
      create_iam_resources_irsa = true
      enabled                   = false
      chart_version             = "1.0.3"
      version                   = "v1.17.3"
      iam_policy_override       = ""
      default_network_policy    = true
      cluster_name              = "cluster"
    },
    var.cluster_autoscaler
  )

  values_cluster_autoscaler = <<VALUES
nameOverride: "${local.cluster_autoscaler["name"]}"
autoDiscovery:
  clusterName: ${local.cluster_autoscaler["cluster_name"]}
awsRegion: ${data.aws_region.current.name}
rbac:
  create: true
  pspEnabled: true
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: "${local.cluster_autoscaler["enabled"] && local.cluster_autoscaler["create_iam_resources_irsa"] ? module.iam_assumable_role_cluster_autoscaler.this_iam_role_arn : ""}"
image:
  tag: ${local.cluster_autoscaler["version"]}
podAnnotations:
  iam.amazonaws.com/role: "${local.cluster_autoscaler["enabled"] && local.cluster_autoscaler["create_iam_resources_kiam"] ? aws_iam_role.eks-cluster-autoscaler-kiam[0].arn : "^$"}"
extraArgs:
  balance-similar-node-groups: true
serviceMonitor:
  enabled: ${local.prometheus_operator["enabled"]}
VALUES
}

module "iam_assumable_role_cluster_autoscaler" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v2.0"
  create_role                   = local.cluster_autoscaler["enabled"] && local.cluster_autoscaler["create_iam_resources_irsa"]
  role_name                     = "tf-eks-${var.cluster-name}-cluster-autoscaler-irsa"
  provider_url                  = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns              = local.cluster_autoscaler["create_iam_resources_irsa"] ? [aws_iam_policy.eks-cluster-autoscaler[0].arn] : []
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.cluster_autoscaler["namespace"]}:${local.cluster_autoscaler["service_account_name"]}"]
}

resource "aws_iam_policy" "eks-cluster-autoscaler" {
  count  = local.cluster_autoscaler["enabled"] && (local.cluster_autoscaler["create_iam_resources_kiam"] || local.cluster_autoscaler["create_iam_resources_irsa"]) ? 1 : 0
  name   = "tf-eks-${var.cluster-name}-cluster-autoscaler"
  policy = local.cluster_autoscaler["iam_policy_override"] == "" ? data.aws_iam_policy_document.cluster_autoscaler.json : local.cluster_autoscaler["iam_policy_override"]
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    sid    = "clusterAutoscalerAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "clusterAutoscalerOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${var.cluster-name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}


resource "aws_iam_role" "eks-cluster-autoscaler-kiam" {
  name  = "tf-eks-${var.cluster-name}-cluster-autoscaler-kiam"
  count = local.cluster_autoscaler["enabled"] && local.cluster_autoscaler["create_iam_resources_kiam"] ? 1 : 0

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

resource "aws_iam_role_policy_attachment" "eks-cluster-autoscaler-kiam" {
  count      = local.cluster_autoscaler["enabled"] && local.cluster_autoscaler["create_iam_resources_kiam"] ? 1 : 0
  role       = aws_iam_role.eks-cluster-autoscaler-kiam[count.index].name
  policy_arn = aws_iam_policy.eks-cluster-autoscaler[count.index].arn
}

resource "kubernetes_namespace" "cluster_autoscaler" {
  count = local.cluster_autoscaler["enabled"] ? 1 : 0

  metadata {
    annotations = {
      "iam.amazonaws.com/permitted" = "${local.cluster_autoscaler["create_iam_resources_kiam"] ? aws_iam_role.eks-cluster-autoscaler-kiam[0].arn : "^$"}"
    }

    labels = {
      name = local.cluster_autoscaler["namespace"]
    }

    name = local.cluster_autoscaler["namespace"]
  }
}

resource "helm_release" "cluster_autoscaler" {
  count                 = local.cluster_autoscaler["enabled"] ? 1 : 0
  repository            = local.cluster_autoscaler["repository"]
  name                  = local.cluster_autoscaler["name"]
  chart                 = local.cluster_autoscaler["chart"]
  version               = local.cluster_autoscaler["chart_version"]
  timeout               = local.cluster_autoscaler["timeout"]
  force_update          = local.cluster_autoscaler["force_update"]
  recreate_pods         = local.cluster_autoscaler["recreate_pods"]
  wait                  = local.cluster_autoscaler["wait"]
  atomic                = local.cluster_autoscaler["atomic"]
  cleanup_on_fail       = local.cluster_autoscaler["cleanup_on_fail"]
  dependency_update     = local.cluster_autoscaler["dependency_update"]
  disable_crd_hooks     = local.cluster_autoscaler["disable_crd_hooks"]
  disable_webhooks      = local.cluster_autoscaler["disable_webhooks"]
  render_subchart_notes = local.cluster_autoscaler["render_subchart_notes"]
  replace               = local.cluster_autoscaler["replace"]
  reset_values          = local.cluster_autoscaler["reset_values"]
  reuse_values          = local.cluster_autoscaler["reuse_values"]
  skip_crds             = local.cluster_autoscaler["skip_crds"]
  verify                = local.cluster_autoscaler["verify"]
  values = [
    local.values_cluster_autoscaler,
    local.cluster_autoscaler["extra_values"]
  ]
  namespace = kubernetes_namespace.cluster_autoscaler.*.metadata.0.name[count.index]

  depends_on = [
    helm_release.kiam,
    helm_release.prometheus_operator
  ]
}

resource "kubernetes_network_policy" "cluster_autoscaler_default_deny" {
  count = local.cluster_autoscaler["enabled"] && local.cluster_autoscaler["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.cluster_autoscaler.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.cluster_autoscaler.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "cluster_autoscaler_allow_namespace" {
  count = local.cluster_autoscaler["enabled"] && local.cluster_autoscaler["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.cluster_autoscaler.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.cluster_autoscaler.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.cluster_autoscaler.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "cluster_autoscaler_allow_monitoring" {
  count = local.cluster_autoscaler["enabled"] && local.cluster_autoscaler["default_network_policy"] && local.prometheus_operator["enabled"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.cluster_autoscaler.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.cluster_autoscaler.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      ports {
        port     = "8085"
        protocol = "TCP"
      }

      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.prometheus_operator.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
