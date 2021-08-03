locals {
  aws-ebs-csi-driver = merge(
    local.helm_defaults,
    {
      name          = local.helm_dependencies[index(local.helm_dependencies.*.name, "aws-ebs-csi-driver")].name
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "aws-ebs-csi-driver")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "aws-ebs-csi-driver")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "aws-ebs-csi-driver")].version
      namespace     = "kube-system"
      create_ns     = false
      service_account_names = {
        controller = "ebs-csi-controller-sa"
        node       = "ebs-csi-node-sa"
      }
      create_iam_resources_irsa = true
      create_storage_class      = true
      storage_class_name        = "ebs-sc"
      is_default_class          = false
      enabled                   = false
      iam_policy_override       = null
      default_network_policy    = true
    },
    var.aws-ebs-csi-driver
  )

  values_aws-ebs-csi-driver = <<VALUES
enableVolumeScheduling: true
enableVolumeResizing: true
enableVolumeSnapshot: true
extraCreateMetadata: true
k8sTagClusterId: ${var.cluster-name}
controller:
  priorityClassName: ${local.priority-class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
  serviceAccount:
    name: ${local.aws-ebs-csi-driver["service_account_names"]["controller"]}
    annotations:
      eks.amazonaws.com/role-arn: "${local.aws-ebs-csi-driver["enabled"] && local.aws-ebs-csi-driver["create_iam_resources_irsa"] ? module.iam_assumable_role_aws-ebs-csi-driver.iam_role_arn : ""}"
node:
  tolerateAllTaints: true
  priorityClassName: ${local.priority-class-ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}
  serviceAccount:
    name: ${local.aws-ebs-csi-driver["service_account_names"]["node"]}
    annotations:
      eks.amazonaws.com/role-arn: "${local.aws-ebs-csi-driver["enabled"] && local.aws-ebs-csi-driver["create_iam_resources_irsa"] ? module.iam_assumable_role_aws-ebs-csi-driver.iam_role_arn : ""}"
VALUES
}

module "iam_assumable_role_aws-ebs-csi-driver" {
  source                     = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                    = "~> 4.0"
  create_role                = local.aws-ebs-csi-driver["enabled"] && local.aws-ebs-csi-driver["create_iam_resources_irsa"]
  role_name                  = "tf-${var.cluster-name}-${local.aws-ebs-csi-driver["name"]}-irsa"
  provider_url               = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns           = local.aws-ebs-csi-driver["enabled"] && local.aws-ebs-csi-driver["create_iam_resources_irsa"] ? [aws_iam_policy.aws-ebs-csi-driver[0].arn] : []
  number_of_role_policy_arns = 1
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:${local.aws-ebs-csi-driver["namespace"]}:${local.aws-ebs-csi-driver["service_account_names"]["controller"]}",
    "system:serviceaccount:${local.aws-ebs-csi-driver["namespace"]}:${local.aws-ebs-csi-driver["service_account_names"]["node"]}"
  ]
  tags = local.tags
}

resource "aws_iam_policy" "aws-ebs-csi-driver" {
  count  = local.aws-ebs-csi-driver["enabled"] && local.aws-ebs-csi-driver["create_iam_resources_irsa"] ? 1 : 0
  name   = "tf-${var.cluster-name}-${local.aws-ebs-csi-driver["name"]}"
  policy = local.aws-ebs-csi-driver["iam_policy_override"] == null ? templatefile("${path.module}/iam/aws-ebs-csi-driver.json", { arn-partition = var.arn-partition }) : local.aws-ebs-csi-driver["iam_policy_override"]
}

resource "kubernetes_namespace" "aws-ebs-csi-driver" {
  count = local.aws-ebs-csi-driver["enabled"] && local.aws-ebs-csi-driver["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name = local.aws-ebs-csi-driver["namespace"]
    }

    name = local.aws-ebs-csi-driver["namespace"]
  }
}

resource "helm_release" "aws-ebs-csi-driver" {
  count                 = local.aws-ebs-csi-driver["enabled"] ? 1 : 0
  repository            = local.aws-ebs-csi-driver["repository"]
  name                  = local.aws-ebs-csi-driver["name"]
  chart                 = local.aws-ebs-csi-driver["chart"]
  version               = local.aws-ebs-csi-driver["chart_version"]
  timeout               = local.aws-ebs-csi-driver["timeout"]
  force_update          = local.aws-ebs-csi-driver["force_update"]
  recreate_pods         = local.aws-ebs-csi-driver["recreate_pods"]
  wait                  = local.aws-ebs-csi-driver["wait"]
  atomic                = local.aws-ebs-csi-driver["atomic"]
  cleanup_on_fail       = local.aws-ebs-csi-driver["cleanup_on_fail"]
  dependency_update     = local.aws-ebs-csi-driver["dependency_update"]
  disable_crd_hooks     = local.aws-ebs-csi-driver["disable_crd_hooks"]
  disable_webhooks      = local.aws-ebs-csi-driver["disable_webhooks"]
  render_subchart_notes = local.aws-ebs-csi-driver["render_subchart_notes"]
  replace               = local.aws-ebs-csi-driver["replace"]
  reset_values          = local.aws-ebs-csi-driver["reset_values"]
  reuse_values          = local.aws-ebs-csi-driver["reuse_values"]
  skip_crds             = local.aws-ebs-csi-driver["skip_crds"]
  verify                = local.aws-ebs-csi-driver["verify"]
  values = [
    local.values_aws-ebs-csi-driver,
    local.aws-ebs-csi-driver["extra_values"]
  ]
  namespace = local.aws-ebs-csi-driver["create_ns"] ? kubernetes_namespace.aws-ebs-csi-driver.*.metadata.0.name[count.index] : local.aws-ebs-csi-driver["namespace"]
}

resource "kubernetes_storage_class" "aws-ebs-csi-driver" {
  count = local.aws-ebs-csi-driver["enabled"] && local.aws-ebs-csi-driver["create_storage_class"] ? 1 : 0
  metadata {
    name = local.aws-ebs-csi-driver["storage_class_name"]
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = tostring(local.aws-ebs-csi-driver["is_default_class"])
    }
  }
  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
}

resource "kubernetes_network_policy" "aws-ebs-csi-driver_default_deny" {
  count = local.aws-ebs-csi-driver["create_ns"] && local.aws-ebs-csi-driver["enabled"] && local.aws-ebs-csi-driver["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.aws-ebs-csi-driver.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.aws-ebs-csi-driver.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "aws-ebs-csi-driver_allow_namespace" {
  count = local.aws-ebs-csi-driver["create_ns"] && local.aws-ebs-csi-driver["enabled"] && local.aws-ebs-csi-driver["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.aws-ebs-csi-driver.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.aws-ebs-csi-driver.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.aws-ebs-csi-driver.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
