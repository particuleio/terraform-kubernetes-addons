locals {
  aws-efs-csi-driver = merge(
    local.helm_defaults,
    {
      name                      = local.helm_dependencies[index(local.helm_dependencies.*.name, "aws-efs-csi-driver")].name
      chart                     = local.helm_dependencies[index(local.helm_dependencies.*.name, "aws-efs-csi-driver")].name
      repository                = local.helm_dependencies[index(local.helm_dependencies.*.name, "aws-efs-csi-driver")].repository
      chart_version             = local.helm_dependencies[index(local.helm_dependencies.*.name, "aws-efs-csi-driver")].version
      namespace                 = "kube-system"
      create_ns                 = false
      create_iam_resources_irsa = true
      create_storage_class      = true
      storage_class_name        = "efs-sc"
      is_default_class          = false
      enabled                   = false
      iam_policy_override       = null
      default_network_policy    = true
    },
    var.aws-efs-csi-driver
  )

  values_aws-efs-csi-driver = <<VALUES
k8sTagClusterId: ${var.cluster-name}
VALUES
}

resource "kubernetes_namespace" "aws-efs-csi-driver" {
  count = local.aws-efs-csi-driver["enabled"] && local.aws-efs-csi-driver["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name = local.aws-efs-csi-driver["namespace"]
    }

    name = local.aws-efs-csi-driver["namespace"]
  }
}

resource "helm_release" "aws-efs-csi-driver" {
  count                 = local.aws-efs-csi-driver["enabled"] ? 1 : 0
  repository            = local.aws-efs-csi-driver["repository"]
  name                  = local.aws-efs-csi-driver["name"]
  chart                 = local.aws-efs-csi-driver["chart"]
  version               = local.aws-efs-csi-driver["chart_version"]
  timeout               = local.aws-efs-csi-driver["timeout"]
  force_update          = local.aws-efs-csi-driver["force_update"]
  recreate_pods         = local.aws-efs-csi-driver["recreate_pods"]
  wait                  = local.aws-efs-csi-driver["wait"]
  atomic                = local.aws-efs-csi-driver["atomic"]
  cleanup_on_fail       = local.aws-efs-csi-driver["cleanup_on_fail"]
  dependency_update     = local.aws-efs-csi-driver["dependency_update"]
  disable_crd_hooks     = local.aws-efs-csi-driver["disable_crd_hooks"]
  disable_webhooks      = local.aws-efs-csi-driver["disable_webhooks"]
  render_subchart_notes = local.aws-efs-csi-driver["render_subchart_notes"]
  replace               = local.aws-efs-csi-driver["replace"]
  reset_values          = local.aws-efs-csi-driver["reset_values"]
  reuse_values          = local.aws-efs-csi-driver["reuse_values"]
  skip_crds             = local.aws-efs-csi-driver["skip_crds"]
  verify                = local.aws-efs-csi-driver["verify"]
  values = [
    local.values_aws-efs-csi-driver,
    local.aws-efs-csi-driver["extra_values"]
  ]
  namespace = local.aws-efs-csi-driver["create_ns"] ? kubernetes_namespace.aws-efs-csi-driver.*.metadata.0.name[count.index] : local.aws-efs-csi-driver["namespace"]
}

resource "kubernetes_storage_class" "aws-efs-csi-driver" {
  count = local.aws-efs-csi-driver["enabled"] && local.aws-efs-csi-driver["create_storage_class"] ? 1 : 0
  metadata {
    name = local.aws-efs-csi-driver["storage_class_name"]
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = tostring(local.aws-efs-csi-driver["is_default_class"])
    }
  }
  storage_provisioner = "efs.csi.aws.com"
}

resource "kubernetes_network_policy" "aws-efs-csi-driver_default_deny" {
  count = local.aws-efs-csi-driver["create_ns"] && local.aws-efs-csi-driver["enabled"] && local.aws-efs-csi-driver["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.aws-efs-csi-driver.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.aws-efs-csi-driver.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "aws-efs-csi-driver_allow_namespace" {
  count = local.aws-efs-csi-driver["create_ns"] && local.aws-efs-csi-driver["enabled"] && local.aws-efs-csi-driver["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.aws-efs-csi-driver.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.aws-efs-csi-driver.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.aws-efs-csi-driver.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
