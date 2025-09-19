locals {
  yet-another-cloudwatch-exporter = merge(
    local.helm_defaults,
    {
      name                      = local.helm_dependencies[index(local.helm_dependencies.*.name, "yet-another-cloudwatch-exporter")].name
      chart                     = local.helm_dependencies[index(local.helm_dependencies.*.name, "yet-another-cloudwatch-exporter")].name
      repository                = local.helm_dependencies[index(local.helm_dependencies.*.name, "yet-another-cloudwatch-exporter")].repository
      chart_version             = local.helm_dependencies[index(local.helm_dependencies.*.name, "yet-another-cloudwatch-exporter")].version
      namespace                 = "monitoring"
      create_ns                 = false
      enabled                   = false
      default_network_policy    = true
      service_account_name      = "yace"
      create_iam_resources_irsa = true
      iam_policy_override       = null
      name_prefix               = "${var.cluster-name}-yace"
    },
    var.yet-another-cloudwatch-exporter
  )

  values_yet-another-cloudwatch-exporter = <<-VALUES
    serviceMonitor:
      enabled: ${local.kube-prometheus-stack["enabled"] || local.victoria-metrics-k8s-stack["enabled"]}
    serviceAccount:
      name: ${local.yet-another-cloudwatch-exporter["service_account_name"]}
      annotations:
        eks.amazonaws.com/role-arn: "${local.yet-another-cloudwatch-exporter["enabled"] && local.yet-another-cloudwatch-exporter["create_iam_resources_irsa"] ? module.iam_assumable_role_yet-another-cloudwatch-exporter.iam_role_arn : ""}"
    VALUES
}

module "iam_assumable_role_yet-another-cloudwatch-exporter" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> 5.0"
  create_role                   = local.yet-another-cloudwatch-exporter["enabled"] && local.yet-another-cloudwatch-exporter["create_iam_resources_irsa"]
  role_name                     = local.yet-another-cloudwatch-exporter["name_prefix"]
  provider_url                  = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns              = local.yet-another-cloudwatch-exporter["enabled"] && local.yet-another-cloudwatch-exporter["create_iam_resources_irsa"] ? [aws_iam_policy.yet-another-cloudwatch-exporter[0].arn] : []
  number_of_role_policy_arns    = 1
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.yet-another-cloudwatch-exporter["namespace"]}:${local.yet-another-cloudwatch-exporter["service_account_name"]}"]
  tags                          = local.tags
}

resource "aws_iam_policy" "yet-another-cloudwatch-exporter" {
  count  = local.yet-another-cloudwatch-exporter["enabled"] && local.yet-another-cloudwatch-exporter["create_iam_resources_irsa"] ? 1 : 0
  name   = local.yet-another-cloudwatch-exporter["name_prefix"]
  policy = local.yet-another-cloudwatch-exporter["iam_policy_override"] == null ? data.aws_iam_policy_document.yet-another-cloudwatch-exporter.json : local.yet-another-cloudwatch-exporter["iam_policy_override"]
  tags   = local.tags
}

data "aws_iam_policy_document" "yet-another-cloudwatch-exporter" {
  statement {
    effect = "Allow"

    actions = [
      "tag:GetResources",
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "ec2:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeTransitGateway*",
      "apigateway:GET",
      "dms:DescribeReplicationInstances",
      "dms:DescribeReplicationTasks"
    ]

    resources = ["*"]
  }
}

resource "kubernetes_namespace" "yet-another-cloudwatch-exporter" {
  count = local.yet-another-cloudwatch-exporter["enabled"] && local.yet-another-cloudwatch-exporter["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name                               = local.yet-another-cloudwatch-exporter["namespace"]
      "${local.labels_prefix}/component" = "monitoring"
    }

    name = local.yet-another-cloudwatch-exporter["namespace"]
  }
}

resource "helm_release" "yet-another-cloudwatch-exporter" {
  count                 = local.yet-another-cloudwatch-exporter["enabled"] ? 1 : 0
  repository            = local.yet-another-cloudwatch-exporter["repository"]
  name                  = local.yet-another-cloudwatch-exporter["name"]
  chart                 = local.yet-another-cloudwatch-exporter["chart"]
  version               = local.yet-another-cloudwatch-exporter["chart_version"]
  timeout               = local.yet-another-cloudwatch-exporter["timeout"]
  force_update          = local.yet-another-cloudwatch-exporter["force_update"]
  recreate_pods         = local.yet-another-cloudwatch-exporter["recreate_pods"]
  wait                  = local.yet-another-cloudwatch-exporter["wait"]
  atomic                = local.yet-another-cloudwatch-exporter["atomic"]
  cleanup_on_fail       = local.yet-another-cloudwatch-exporter["cleanup_on_fail"]
  dependency_update     = local.yet-another-cloudwatch-exporter["dependency_update"]
  disable_crd_hooks     = local.yet-another-cloudwatch-exporter["disable_crd_hooks"]
  disable_webhooks      = local.yet-another-cloudwatch-exporter["disable_webhooks"]
  render_subchart_notes = local.yet-another-cloudwatch-exporter["render_subchart_notes"]
  replace               = local.yet-another-cloudwatch-exporter["replace"]
  reset_values          = local.yet-another-cloudwatch-exporter["reset_values"]
  reuse_values          = local.yet-another-cloudwatch-exporter["reuse_values"]
  skip_crds             = local.yet-another-cloudwatch-exporter["skip_crds"]
  verify                = local.yet-another-cloudwatch-exporter["verify"]
  values = [
    local.values_yet-another-cloudwatch-exporter,
    local.yet-another-cloudwatch-exporter["extra_values"]
  ]
  namespace = local.yet-another-cloudwatch-exporter["create_ns"] ? kubernetes_namespace.yet-another-cloudwatch-exporter.*.metadata.0.name[count.index] : local.yet-another-cloudwatch-exporter["namespace"]

  depends_on = [
    kubectl_manifest.prometheus-operator_crds
  ]
}

resource "kubernetes_network_policy" "yet-another-cloudwatch-exporter_default_deny" {
  count = local.yet-another-cloudwatch-exporter["create_ns"] && local.yet-another-cloudwatch-exporter["enabled"] && local.yet-another-cloudwatch-exporter["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.yet-another-cloudwatch-exporter.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.yet-another-cloudwatch-exporter.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "yet-another-cloudwatch-exporter_allow_namespace" {
  count = local.yet-another-cloudwatch-exporter["create_ns"] && local.yet-another-cloudwatch-exporter["enabled"] && local.yet-another-cloudwatch-exporter["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.yet-another-cloudwatch-exporter.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.yet-another-cloudwatch-exporter.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.yet-another-cloudwatch-exporter.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
