locals {
  cluster-autoscaler = merge(
    local.helm_defaults,
    {
      name                      = local.helm_dependencies[index(local.helm_dependencies.*.name, "cluster-autoscaler")].name
      chart                     = local.helm_dependencies[index(local.helm_dependencies.*.name, "cluster-autoscaler")].name
      repository                = local.helm_dependencies[index(local.helm_dependencies.*.name, "cluster-autoscaler")].repository
      chart_version             = local.helm_dependencies[index(local.helm_dependencies.*.name, "cluster-autoscaler")].version
      namespace                 = "cluster-autoscaler"
      service_account_name      = "cluster-autoscaler"
      create_iam_resources_irsa = true
      enabled                   = false
      iam_policy_override       = null
      default_network_policy    = true
      name_prefix               = "${var.cluster-name}-cluster-autoscaler"
    },
    var.cluster-autoscaler
  )

  values_cluster-autoscaler = <<VALUES
nameOverride: "${local.cluster-autoscaler["name"]}"
autoDiscovery:
  clusterName: ${var.cluster-name}
awsRegion: ${data.aws_region.current.name}
rbac:
  create: true
  serviceAccount:
    name: ${local.cluster-autoscaler["service_account_name"]}
    annotations:
      eks.amazonaws.com/role-arn: "${local.cluster-autoscaler["enabled"] && local.cluster-autoscaler["create_iam_resources_irsa"] ? module.iam_assumable_role_cluster-autoscaler.iam_role_arn : ""}"
extraArgs:
  balance-similar-node-groups: true
  skip-nodes-with-local-storage: false
  balancing-ignore-label_1: topology.ebs.csi.aws.com/zone
  balancing-ignore-label_2: eks.amazonaws.com/nodegroup
  balancing-ignore-label_3: eks.amazonaws.com/nodegroup-image
  balancing-ignore-label_4: eks.amazonaws.com/sourceLaunchTemplateId
  balancing-ignore-label_5: eks.amazonaws.com/sourceLaunchTemplateVersion

serviceMonitor:
  enabled: ${local.kube-prometheus-stack["enabled"] || local.victoria-metrics-k8s-stack["enabled"]}
  namespace: ${local.cluster-autoscaler["namespace"]}
priorityClassName: ${local.priority-class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
VALUES
}

module "iam_assumable_role_cluster-autoscaler" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> 5.0"
  create_role                   = local.cluster-autoscaler["enabled"] && local.cluster-autoscaler["create_iam_resources_irsa"]
  role_name                     = local.cluster-autoscaler["name_prefix"]
  provider_url                  = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns              = local.cluster-autoscaler["enabled"] && local.cluster-autoscaler["create_iam_resources_irsa"] ? [aws_iam_policy.cluster-autoscaler[0].arn] : []
  number_of_role_policy_arns    = 1
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.cluster-autoscaler["namespace"]}:${local.cluster-autoscaler["service_account_name"]}"]
  tags                          = local.tags
}

resource "aws_iam_policy" "cluster-autoscaler" {
  count  = local.cluster-autoscaler["enabled"] && local.cluster-autoscaler["create_iam_resources_irsa"] ? 1 : 0
  name   = local.cluster-autoscaler["name_prefix"]
  policy = local.cluster-autoscaler["iam_policy_override"] == null ? data.aws_iam_policy_document.cluster-autoscaler.json : local.cluster-autoscaler["iam_policy_override"]
  tags   = local.tags
}

data "aws_iam_policy_document" "cluster-autoscaler" {
  statement {
    sid    = "clusterAutoscalerAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstanceTypes",
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

resource "kubernetes_namespace" "cluster-autoscaler" {
  count = local.cluster-autoscaler["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.cluster-autoscaler["namespace"]
    }

    name = local.cluster-autoscaler["namespace"]
  }
}

resource "helm_release" "cluster-autoscaler" {
  count                 = local.cluster-autoscaler["enabled"] ? 1 : 0
  repository            = local.cluster-autoscaler["repository"]
  name                  = local.cluster-autoscaler["name"]
  chart                 = local.cluster-autoscaler["chart"]
  version               = local.cluster-autoscaler["chart_version"]
  timeout               = local.cluster-autoscaler["timeout"]
  force_update          = local.cluster-autoscaler["force_update"]
  recreate_pods         = local.cluster-autoscaler["recreate_pods"]
  wait                  = local.cluster-autoscaler["wait"]
  atomic                = local.cluster-autoscaler["atomic"]
  cleanup_on_fail       = local.cluster-autoscaler["cleanup_on_fail"]
  dependency_update     = local.cluster-autoscaler["dependency_update"]
  disable_crd_hooks     = local.cluster-autoscaler["disable_crd_hooks"]
  disable_webhooks      = local.cluster-autoscaler["disable_webhooks"]
  render_subchart_notes = local.cluster-autoscaler["render_subchart_notes"]
  replace               = local.cluster-autoscaler["replace"]
  reset_values          = local.cluster-autoscaler["reset_values"]
  reuse_values          = local.cluster-autoscaler["reuse_values"]
  skip_crds             = local.cluster-autoscaler["skip_crds"]
  verify                = local.cluster-autoscaler["verify"]
  values = [
    local.values_cluster-autoscaler,
    local.cluster-autoscaler["extra_values"]
  ]

  #TODO(bogdando): create a shared template and refer it in addons (copy-pasta until then)
  dynamic "set" {
    for_each = {
      for c, v in local.images_data.cluster-autoscaler.containers :
      c => v if v.rewrite_values.tag != null
    }
    content {
      name  = set.value.rewrite_values.tag.name
      value = try(local.cluster-autoscaler["containers_versions"][set.value.rewrite_values.tag.name], set.value.rewrite_values.tag.value)
    }
  }
  dynamic "set" {
    for_each = local.images_data.cluster-autoscaler.containers
    content {
      name = set.value.rewrite_values.image.name
      value = set.value.ecr_prepare_images && set.value.source_provided ? "${
        aws_ecr_repository.this[
          format("%s.%s", split(".", set.key)[0], split(".", set.key)[2])
        ].repository_url}${set.value.rewrite_values.image.tail
        }" : set.value.ecr_prepare_images ? "${
        aws_ecr_repository.this[
          format("%s.%s", split(".", set.key)[0], split(".", set.key)[2])
        ].name
      }" : set.value.rewrite_values.image.value
    }
  }
  dynamic "set" {
    for_each = {
      for c, v in local.images_data.cluster-autoscaler.containers :
      c => v if v.rewrite_values.registry != null
    }
    content {
      name = set.value.rewrite_values.registry.name
      # when unset, it should be replaced with the one prepared on ECR
      value = set.value.rewrite_values.registry.value != null ? set.value.rewrite_values.registry.value : split(
        "/", aws_ecr_repository.this[
          format("%s.%s", split(".", set.key)[0], split(".", set.key)[2])
        ].repository_url
      )[0]
    }
  }

  namespace = kubernetes_namespace.cluster-autoscaler.*.metadata.0.name[count.index]

  depends_on = [
    skopeo_copy.this,
    kubectl_manifest.prometheus-operator_crds
  ]
}

resource "kubernetes_network_policy" "cluster-autoscaler_default_deny" {
  count = local.cluster-autoscaler["enabled"] && local.cluster-autoscaler["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.cluster-autoscaler.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.cluster-autoscaler.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "cluster-autoscaler_allow_namespace" {
  count = local.cluster-autoscaler["enabled"] && local.cluster-autoscaler["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.cluster-autoscaler.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.cluster-autoscaler.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.cluster-autoscaler.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "cluster-autoscaler_allow_monitoring" {
  count = local.cluster-autoscaler["enabled"] && local.cluster-autoscaler["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.cluster-autoscaler.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.cluster-autoscaler.*.metadata.0.name[count.index]
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
            "${local.labels_prefix}/component" = "monitoring"
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
