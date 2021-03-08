locals {
  cortex = merge(
    local.helm_defaults,
    {
      name                      = "cortex"
      namespace                 = "cortex"
      chart                     = "cortex"
      repository                = "https://cortexproject.github.io/cortex-helm-chart"
      service_account_name      = "cortex"
      create_iam_resources_irsa = true
      enabled                   = false
      chart_version             = "0.4.0"
      version                   = "v1.7.0"
      iam_policy_override       = ""
      default_network_policy    = true
      cluster_name              = "cluster"
    },
    var.cortex
  )

  values_cortex = <<VALUES
nameOverride: "${local.cortex["name"]}"
autoDiscovery:
  clusterName: ${local.cortex["cluster_name"]}
awsRegion: ${data.aws_region.current.name}
rbac:
  create: true
  pspEnabled: true
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: "${local.cortex["enabled"] && local.cortex["create_iam_resources_irsa"] ? module.iam_assumable_role_cortex[0].this_iam_role_arn : ""}"
VALUES
}

module "iam_assumable_role_cortex" {
  count                         = local.cortex["enabled"] && local.cortex["create_iam_resources_irsa"] ? 1 : 0
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v2.0"
  create_role                   = local.cortex["enabled"] && local.cortex["create_iam_resources_irsa"]
  role_name                     = "tf-eks-${var.cluster-name}-cortex-irsa"
  provider_url                  = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns              = local.cortex["create_iam_resources_irsa"] ? [aws_iam_policy.eks-cortex[0].arn] : []
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.cortex["namespace"]}:${local.cortex["service_account_name"]}"]
}

resource "aws_iam_policy" "eks-cortex" {
  count  = local.cortex["enabled"] ? 1 : 0
  name   = "tf-eks-${var.cluster-name}-cortex"
  policy = local.cortex["iam_policy_override"] == "" ? data.aws_iam_policy_document.cortex[count.index].json : local.cortex["iam_policy_override"]
}

data "aws_iam_policy_document" "cortex" {
  count = local.cortex["enabled"] ? 1 : 0
  version = "2012-10-17"
  statement {
    actions = [
      "s3:*",
    ]
    resources = ["*"]
    effect    = "Allow"
  }
}

resource "kubernetes_namespace" "cortex" {
  count = local.cortex["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.cortex["namespace"]
    }

    name = local.cortex["namespace"]
  }
}

resource "helm_release" "cortex" {
  count                 = local.cortex["enabled"] ? 1 : 0
  repository            = local.cortex["repository"]
  name                  = local.cortex["name"]
  chart                 = local.cortex["chart"]
  version               = local.cortex["chart_version"]
  timeout               = local.cortex["timeout"]
  force_update          = local.cortex["force_update"]
  recreate_pods         = local.cortex["recreate_pods"]
  wait                  = local.cortex["wait"]
  atomic                = local.cortex["atomic"]
  cleanup_on_fail       = local.cortex["cleanup_on_fail"]
  dependency_update     = local.cortex["dependency_update"]
  disable_crd_hooks     = local.cortex["disable_crd_hooks"]
  disable_webhooks      = local.cortex["disable_webhooks"]
  render_subchart_notes = local.cortex["render_subchart_notes"]
  replace               = local.cortex["replace"]
  reset_values          = local.cortex["reset_values"]
  reuse_values          = local.cortex["reuse_values"]
  skip_crds             = local.cortex["skip_crds"]
  verify                = local.cortex["verify"]
  # values = [
  #   local.values_cortex,
  #   local.cortex["extra_values"]
  # ]
  values                = [templatefile("${path.module}/templates/cortex-values.yaml", {}), local.cortex["extra_values"]]
  namespace = kubernetes_namespace.cortex.*.metadata.0.name[count.index]
}

resource "kubernetes_network_policy" "cortex_default_deny" {
  count = local.cortex["enabled"] && local.cortex["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.cortex.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.cortex.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "cortex_allow_namespace" {
  count = local.cortex["enabled"] && local.cortex["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.cortex.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.cortex.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.cortex.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
