locals {
  velero = merge(
    local.helm_defaults,
    {
      name                      = local.helm_dependencies[index(local.helm_dependencies.*.name, "velero")].name
      chart                     = local.helm_dependencies[index(local.helm_dependencies.*.name, "velero")].name
      repository                = local.helm_dependencies[index(local.helm_dependencies.*.name, "velero")].repository
      chart_version             = local.helm_dependencies[index(local.helm_dependencies.*.name, "velero")].version
      namespace                 = "velero"
      service_account_name      = "velero"
      enabled                   = false
      create_iam_resources_irsa = true
      iam_policy_override       = null
      create_bucket             = true
      bucket                    = "${var.cluster-name}-velero"
      bucket_force_destroy      = false
      bucket_enforce_tls        = false
      allowed_cidrs             = ["0.0.0.0/0"]
      default_network_policy    = true
      kms_key_arn_access_list   = []
      name_prefix               = "${var.cluster-name}-velero"
    },
    var.velero
  )

  values_velero = <<VALUES
metrics:
  serviceMonitor:
    enabled: ${local.kube-prometheus-stack["enabled"] || local.victoria-metrics-k8s-stack["enabled"]}
configuration:
  namespace: ${local.velero.namespace}
  features: EnableCSI
  backupStorageLocation:
    - name: aws
      provider: aws
      bucket: ${local.velero.bucket}
      default: true
      config:
        region: ${data.aws_region.current.name}
  volumeSnapshotLocation:
    - name: aws
      provider: aws
      config:
        region: ${data.aws_region.current.name}
serviceAccount:
  server:
    name: ${local.velero["service_account_name"]}
    annotations:
      eks.amazonaws.com/role-arn: "${local.velero["enabled"] && local.velero["create_iam_resources_irsa"] ? module.iam_assumable_role_velero.iam_role_arn : ""}"
priorityClassName: ${local.priority-class-ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}
credentials:
  useSecret: false
initContainers:
   - name: velero-plugin-for-aws
     image: velero/velero-plugin-for-aws:v1.9.2
     imagePullPolicy: IfNotPresent
     volumeMounts:
       - mountPath: /target
         name: plugins
VALUES

}

module "iam_assumable_role_velero" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> 5.0"
  create_role                   = local.velero["enabled"] && local.velero["create_iam_resources_irsa"]
  role_name                     = local.velero["name_prefix"]
  provider_url                  = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns              = local.velero["enabled"] && local.velero["create_iam_resources_irsa"] ? [aws_iam_policy.velero[0].arn] : []
  number_of_role_policy_arns    = 1
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.velero["namespace"]}:${local.velero["service_account_name"]}"]
  tags                          = local.tags
}

resource "aws_iam_policy" "velero" {
  count  = local.velero["enabled"] && local.velero["create_iam_resources_irsa"] ? 1 : 0
  name   = local.velero["name_prefix"]
  policy = local.velero["iam_policy_override"] == null ? data.aws_iam_policy_document.velero.0.json : local.velero["iam_policy_override"]
  tags   = local.tags
}

data "aws_iam_policy_document" "velero" {
  count = local.velero.enabled && local.velero.create_iam_resources_irsa ? 1 : 0
  source_policy_documents = [
    data.aws_iam_policy_document.velero_default.0.json,
    local.velero.kms_key_arn_access_list != [] ? data.aws_iam_policy_document.velero_kms.0.json : jsonencode({})
  ]
}

data "aws_iam_policy_document" "velero_default" {
  count = local.velero.enabled && local.velero.create_iam_resources_irsa ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts"
    ]
    resources = ["arn:aws:s3:::${local.velero.bucket}/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]
    resources = ["arn:aws:s3:::${local.velero.bucket}"]
  }
}

data "aws_iam_policy_document" "velero_kms" {
  count = local.velero.enabled && local.velero.create_iam_resources_irsa && local.velero.kms_key_arn_access_list != [] ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = local.velero.kms_key_arn_access_list
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = local.velero.kms_key_arn_access_list
  }
}

module "velero_thanos_bucket" {
  create_bucket = local.velero.enabled && local.velero.create_bucket

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  force_destroy = local.velero.bucket_force_destroy

  bucket = local.velero.bucket
  acl    = "private"

  versioning = {
    status = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  logging = local.s3-logging.enabled ? {
    target_bucket = local.s3-logging.create_bucket ? module.s3_logging_bucket.s3_bucket_id : local.s3-logging.custom_bucket_id
    target_prefix = "${var.cluster-name}/${local.velero.name}/"
  } : {}

  attach_deny_insecure_transport_policy = local.velero.bucket_enforce_tls

  tags = local.tags
}

resource "kubernetes_namespace" "velero" {
  count = local.velero["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.velero["namespace"]
    }

    name = local.velero["namespace"]
  }
}

resource "helm_release" "velero" {
  count                 = local.velero["enabled"] ? 1 : 0
  repository            = local.velero["repository"]
  name                  = local.velero["name"]
  chart                 = local.velero["chart"]
  version               = local.velero["chart_version"]
  timeout               = local.velero["timeout"]
  force_update          = local.velero["force_update"]
  recreate_pods         = local.velero["recreate_pods"]
  wait                  = local.velero["wait"]
  atomic                = local.velero["atomic"]
  cleanup_on_fail       = local.velero["cleanup_on_fail"]
  dependency_update     = local.velero["dependency_update"]
  disable_crd_hooks     = local.velero["disable_crd_hooks"]
  disable_webhooks      = local.velero["disable_webhooks"]
  render_subchart_notes = local.velero["render_subchart_notes"]
  replace               = local.velero["replace"]
  reset_values          = local.velero["reset_values"]
  reuse_values          = local.velero["reuse_values"]
  skip_crds             = local.velero["skip_crds"]
  verify                = local.velero["verify"]
  values = compact([
    local.values_velero,
    local.velero["extra_values"]
  ])
  namespace = kubernetes_namespace.velero.*.metadata.0.name[count.index]

  depends_on = [
    kubectl_manifest.prometheus-operator_crds
  ]
}

resource "kubernetes_network_policy" "velero_default_deny" {
  count = local.velero["enabled"] && local.velero["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.velero.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.velero.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "velero_allow_namespace" {
  count = local.velero["enabled"] && local.velero["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.velero.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.velero.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.velero.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "velero_allow_monitoring" {
  count = local.velero["enabled"] && local.velero["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.velero.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.velero.*.metadata.0.name[count.index]
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
