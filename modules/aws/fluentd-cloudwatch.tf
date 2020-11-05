locals {

  fluentd_cloudwatch = merge(
    local.helm_defaults,
    {
      name                             = "fluentd-cloudwatch"
      namespace                        = "fluentd-cloudwatch"
      chart                            = "fluentd-cloudwatch"
      repository                       = "https://kubernetes-charts-incubator.storage.googleapis.com"
      service_account_name             = "fluentd-cloudwatch"
      create_iam_resources_kiam        = false
      create_iam_resources_irsa        = true
      enabled                          = false
      chart_version                    = "0.13.0"
      version                          = "v1.11-debian-cloudwatch-1"
      iam_policy_override              = ""
      default_network_policy           = true
      containers_log_retention_in_days = 180
    },
    var.fluentd_cloudwatch
  )

  values_fluentd_cloudwatch = <<VALUES
image:
  tag: ${local.fluentd_cloudwatch["version"]}
rbac:
  create: true
  pspEnabled: true
  serviceAccountAnnotations:
    eks.amazonaws.com/role-arn: "${local.fluentd_cloudwatch["enabled"] && local.fluentd_cloudwatch["create_iam_resources_irsa"] ? module.iam_assumable_role_fluentd_cloudwatch.this_iam_role_arn : ""}"
tolerations:
  - operator: Exists
awsRole: "${local.fluentd_cloudwatch["enabled"] && local.fluentd_cloudwatch["create_iam_resources_kiam"] ? aws_iam_role.eks-fluentd-cloudwatch-kiam[0].arn : ""}"
awsRegion: "${data.aws_region.current.name}"
logGroupName: "${local.fluentd_cloudwatch["enabled"] ? aws_cloudwatch_log_group.eks-fluentd-cloudwatch-log-group[0].name : ""}"
extraVars:
  - "{ name: FLUENT_UID, value: '0' }"
updateStrategy:
  type: RollingUpdate
priorityClassName: ${local.priority_class_ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}
VALUES
}

module "iam_assumable_role_fluentd_cloudwatch" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v2.0"
  create_role                   = local.fluentd_cloudwatch["enabled"] && local.fluentd_cloudwatch["create_iam_resources_irsa"]
  role_name                     = "tf-eks-${var.cluster-name}-fluentd-cloudwatch-irsa"
  provider_url                  = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns              = local.fluentd_cloudwatch["enabled"] && local.fluentd_cloudwatch["create_iam_resources_irsa"] ? [aws_iam_policy.eks-fluentd-cloudwatch[0].arn] : []
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.fluentd_cloudwatch["namespace"]}:${local.fluentd_cloudwatch["service_account_name"]}"]
}

resource "aws_iam_policy" "eks-fluentd-cloudwatch" {
  count  = local.fluentd_cloudwatch["enabled"] && (local.fluentd_cloudwatch["create_iam_resources_kiam"] || local.fluentd_cloudwatch["create_iam_resources_irsa"]) ? 1 : 0
  name   = "tf-eks-${var.cluster-name}-fluentd-cloudwatch"
  policy = local.fluentd_cloudwatch["iam_policy_override"] == "" ? data.aws_iam_policy_document.fluentd_cloudwatch.json : local.fluentd_cloudwatch["iam_policy_override"]
}

data "aws_iam_policy_document" "fluentd_cloudwatch" {
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

resource "aws_cloudwatch_log_group" "eks-fluentd-cloudwatch-log-group" {
  count             = local.fluentd_cloudwatch["enabled"] ? 1 : 0
  name              = "/aws/eks/${var.cluster-name}/containers"
  retention_in_days = local.fluentd_cloudwatch["containers_log_retention_in_days"]
}

resource "aws_iam_role" "eks-fluentd-cloudwatch-kiam" {
  name  = "tf-eks-${var.cluster-name}-fluentd-cloudwatch-kiam"
  count = local.fluentd_cloudwatch["enabled"] && local.fluentd_cloudwatch["create_iam_resources_kiam"] ? 1 : 0

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

resource "aws_iam_role_policy_attachment" "eks-fluentd-cloudwatch-kiam" {
  count      = local.fluentd_cloudwatch["enabled"] && local.fluentd_cloudwatch["create_iam_resources_kiam"] ? 1 : 0
  role       = aws_iam_role.eks-fluentd-cloudwatch-kiam[count.index].name
  policy_arn = aws_iam_policy.eks-fluentd-cloudwatch[count.index].arn
}

resource "kubernetes_namespace" "fluentd_cloudwatch" {
  count = local.fluentd_cloudwatch["enabled"] ? 1 : 0

  metadata {
    annotations = {
      "iam.amazonaws.com/permitted" = "${local.fluentd_cloudwatch["create_iam_resources_kiam"] ? aws_iam_role.eks-fluentd-cloudwatch-kiam[0].arn : "^$"}"
    }

    labels = {
      name = local.fluentd_cloudwatch["namespace"]
    }

    name = local.fluentd_cloudwatch["namespace"]
  }
}

resource "helm_release" "fluentd_cloudwatch" {
  count                 = local.fluentd_cloudwatch["enabled"] ? 1 : 0
  repository            = local.fluentd_cloudwatch["repository"]
  name                  = local.fluentd_cloudwatch["name"]
  chart                 = local.fluentd_cloudwatch["chart"]
  version               = local.fluentd_cloudwatch["chart_version"]
  timeout               = local.fluentd_cloudwatch["timeout"]
  force_update          = local.fluentd_cloudwatch["force_update"]
  recreate_pods         = local.fluentd_cloudwatch["recreate_pods"]
  wait                  = local.fluentd_cloudwatch["wait"]
  atomic                = local.fluentd_cloudwatch["atomic"]
  cleanup_on_fail       = local.fluentd_cloudwatch["cleanup_on_fail"]
  dependency_update     = local.fluentd_cloudwatch["dependency_update"]
  disable_crd_hooks     = local.fluentd_cloudwatch["disable_crd_hooks"]
  disable_webhooks      = local.fluentd_cloudwatch["disable_webhooks"]
  render_subchart_notes = local.fluentd_cloudwatch["render_subchart_notes"]
  replace               = local.fluentd_cloudwatch["replace"]
  reset_values          = local.fluentd_cloudwatch["reset_values"]
  reuse_values          = local.fluentd_cloudwatch["reuse_values"]
  skip_crds             = local.fluentd_cloudwatch["skip_crds"]
  verify                = local.fluentd_cloudwatch["verify"]
  values = [
    local.values_fluentd_cloudwatch,
    local.fluentd_cloudwatch["extra_values"]
  ]
  namespace = kubernetes_namespace.fluentd_cloudwatch.*.metadata.0.name[count.index]

  depends_on = [
    helm_release.kiam
  ]
}

resource "kubernetes_network_policy" "fluentd_cloudwatch_default_deny" {
  count = local.fluentd_cloudwatch["enabled"] && local.fluentd_cloudwatch["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.fluentd_cloudwatch.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.fluentd_cloudwatch.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "fluentd_cloudwatch_allow_namespace" {
  count = local.fluentd_cloudwatch["enabled"] && local.fluentd_cloudwatch["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.fluentd_cloudwatch.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.fluentd_cloudwatch.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.fluentd_cloudwatch.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

