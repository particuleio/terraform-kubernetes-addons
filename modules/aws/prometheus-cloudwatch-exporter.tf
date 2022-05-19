locals {
  prometheus-cloudwatch-exporter = merge(
    local.helm_defaults,
    {
      name                      = local.helm_dependencies[index(local.helm_dependencies.*.name, "prometheus-cloudwatch-exporter")].name
      chart                     = local.helm_dependencies[index(local.helm_dependencies.*.name, "prometheus-cloudwatch-exporter")].name
      repository                = local.helm_dependencies[index(local.helm_dependencies.*.name, "prometheus-cloudwatch-exporter")].repository
      chart_version             = local.helm_dependencies[index(local.helm_dependencies.*.name, "prometheus-cloudwatch-exporter")].version
      namespace                 = "monitoring"
      create_ns                 = false
      enabled                   = false
      default_network_policy    = true
      service_account_name      = "prometheus-cloudwatch-exporter"
      create_iam_resources_irsa = true
      iam_policy_override       = null
      name_prefix               = "${var.cluster-name}-prom-cw-exporter"
    },
    var.prometheus-cloudwatch-exporter
  )

  values_prometheus-cloudwatch-exporter = <<-VALUES
    serviceMonitor:
      enabled: ${local.kube-prometheus-stack["enabled"] || local.victoria-metrics-k8s-stack["enabled"]}
    aws:
      role: "${local.prometheus-cloudwatch-exporter["enabled"] && local.prometheus-cloudwatch-exporter["create_iam_resources_irsa"] ? module.iam_assumable_role_prometheus-cloudwatch-exporter.iam_role_arn : ""}"
    serviceAccount:
      name: ${local.prometheus-cloudwatch-exporter["service_account_name"]}
      annotations:
        eks.amazonaws.com/role-arn: "${local.prometheus-cloudwatch-exporter["enabled"] && local.prometheus-cloudwatch-exporter["create_iam_resources_irsa"] ? module.iam_assumable_role_prometheus-cloudwatch-exporter.iam_role_arn : ""}"
    VALUES
}

module "iam_assumable_role_prometheus-cloudwatch-exporter" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> 5.0"
  create_role                   = local.prometheus-cloudwatch-exporter["enabled"] && local.prometheus-cloudwatch-exporter["create_iam_resources_irsa"]
  role_name                     = local.prometheus-cloudwatch-exporter["name_prefix"]
  provider_url                  = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns              = local.prometheus-cloudwatch-exporter["enabled"] && local.prometheus-cloudwatch-exporter["create_iam_resources_irsa"] ? [aws_iam_policy.prometheus-cloudwatch-exporter[0].arn] : []
  number_of_role_policy_arns    = 1
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.prometheus-cloudwatch-exporter["namespace"]}:${local.prometheus-cloudwatch-exporter["service_account_name"]}"]
  tags                          = local.tags
}

resource "aws_iam_policy" "prometheus-cloudwatch-exporter" {
  count  = local.prometheus-cloudwatch-exporter["enabled"] && local.prometheus-cloudwatch-exporter["create_iam_resources_irsa"] ? 1 : 0
  name   = local.prometheus-cloudwatch-exporter["name_prefix"]
  policy = local.prometheus-cloudwatch-exporter["iam_policy_override"] == null ? data.aws_iam_policy_document.prometheus-cloudwatch-exporter.json : local.prometheus-cloudwatch-exporter["iam_policy_override"]
  tags   = local.tags
}

data "aws_iam_policy_document" "prometheus-cloudwatch-exporter" {
  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricStatistics",
      "tag:GetResources"
    ]

    resources = ["*"]
  }
}

resource "kubernetes_namespace" "prometheus-cloudwatch-exporter" {
  count = local.prometheus-cloudwatch-exporter["enabled"] && local.prometheus-cloudwatch-exporter["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name                               = local.prometheus-cloudwatch-exporter["namespace"]
      "${local.labels_prefix}/component" = "monitoring"
    }

    name = local.prometheus-cloudwatch-exporter["namespace"]
  }
}

resource "helm_release" "prometheus-cloudwatch-exporter" {
  count                 = local.prometheus-cloudwatch-exporter["enabled"] ? 1 : 0
  repository            = local.prometheus-cloudwatch-exporter["repository"]
  name                  = local.prometheus-cloudwatch-exporter["name"]
  chart                 = local.prometheus-cloudwatch-exporter["chart"]
  version               = local.prometheus-cloudwatch-exporter["chart_version"]
  timeout               = local.prometheus-cloudwatch-exporter["timeout"]
  force_update          = local.prometheus-cloudwatch-exporter["force_update"]
  recreate_pods         = local.prometheus-cloudwatch-exporter["recreate_pods"]
  wait                  = local.prometheus-cloudwatch-exporter["wait"]
  atomic                = local.prometheus-cloudwatch-exporter["atomic"]
  cleanup_on_fail       = local.prometheus-cloudwatch-exporter["cleanup_on_fail"]
  dependency_update     = local.prometheus-cloudwatch-exporter["dependency_update"]
  disable_crd_hooks     = local.prometheus-cloudwatch-exporter["disable_crd_hooks"]
  disable_webhooks      = local.prometheus-cloudwatch-exporter["disable_webhooks"]
  render_subchart_notes = local.prometheus-cloudwatch-exporter["render_subchart_notes"]
  replace               = local.prometheus-cloudwatch-exporter["replace"]
  reset_values          = local.prometheus-cloudwatch-exporter["reset_values"]
  reuse_values          = local.prometheus-cloudwatch-exporter["reuse_values"]
  skip_crds             = local.prometheus-cloudwatch-exporter["skip_crds"]
  verify                = local.prometheus-cloudwatch-exporter["verify"]
  values = [
    local.values_prometheus-cloudwatch-exporter,
    local.prometheus-cloudwatch-exporter["extra_values"]
  ]
  namespace = local.prometheus-cloudwatch-exporter["create_ns"] ? kubernetes_namespace.prometheus-cloudwatch-exporter.*.metadata.0.name[count.index] : local.prometheus-cloudwatch-exporter["namespace"]

  depends_on = [
    helm_release.kube-prometheus-stack
  ]
}

resource "kubernetes_network_policy" "prometheus-cloudwatch-exporter_default_deny" {
  count = local.prometheus-cloudwatch-exporter["create_ns"] && local.prometheus-cloudwatch-exporter["enabled"] && local.prometheus-cloudwatch-exporter["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.prometheus-cloudwatch-exporter.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.prometheus-cloudwatch-exporter.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "prometheus-cloudwatch-exporter_allow_namespace" {
  count = local.prometheus-cloudwatch-exporter["create_ns"] && local.prometheus-cloudwatch-exporter["enabled"] && local.prometheus-cloudwatch-exporter["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.prometheus-cloudwatch-exporter.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.prometheus-cloudwatch-exporter.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.prometheus-cloudwatch-exporter.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
