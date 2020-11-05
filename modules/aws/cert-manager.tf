locals {

  cert_manager = merge(
    local.helm_defaults,
    {
      name                           = "cert-manager"
      namespace                      = "cert-manager"
      chart                          = "cert-manager"
      repository                     = "https://charts.jetstack.io"
      service_account_name           = "cert-manager"
      create_iam_resources_kiam      = false
      create_iam_resources_irsa      = true
      enabled                        = false
      chart_version                  = "v1.0.0"
      version                        = "v1.0.0"
      iam_policy_override            = ""
      default_network_policy         = true
      acme_email                     = "contact@acme.com"
      enable_default_cluster_issuers = false
      allowed_cidr                   = "0.0.0.0/0"
    },
    var.cert_manager
  )

  values_cert_manager = <<VALUES
image:
  tag: ${local.cert_manager["version"]}
global:
  podSecurityPolicy:
    enabled: true
    useAppArmor: false
  priorityClassName: ${local.priority_class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
podAnnotations:
  iam.amazonaws.com/role: "${local.cert_manager["enabled"] && local.cert_manager["create_iam_resources_kiam"] ? aws_iam_role.eks-cert-manager-kiam[0].arn : ""}"
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: "${local.cert_manager["enabled"] && local.cert_manager["create_iam_resources_irsa"] ? module.iam_assumable_role_cert_manager.this_iam_role_arn : ""}"
prometheus:
  servicemonitor:
    enabled: ${local.prometheus_operator["enabled"]}
securityContext:
  enabled: true
  fsGroup: 1001
installCRDs: true
VALUES

}

module "iam_assumable_role_cert_manager" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v2.0"
  create_role                   = local.cert_manager["enabled"] && local.cert_manager["create_iam_resources_irsa"]
  role_name                     = "tf-eks-${var.cluster-name}-cert-manager-irsa"
  provider_url                  = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns              = local.cert_manager["enabled"] && local.cert_manager["create_iam_resources_irsa"] ? [aws_iam_policy.eks-cert-manager[0].arn] : []
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.cert_manager["namespace"]}:${local.cert_manager["service_account_name"]}"]
}

resource "aws_iam_policy" "eks-cert-manager" {
  count  = local.cert_manager["enabled"] && (local.cert_manager["create_iam_resources_kiam"] || local.cert_manager["create_iam_resources_irsa"]) ? 1 : 0
  name   = "tf-eks-${var.cluster-name}-cert-manager"
  policy = local.cert_manager["iam_policy_override"] == "" ? data.aws_iam_policy_document.cert_manager.json : local.cert_manager["iam_policy_override"]
}

data "aws_iam_policy_document" "cert_manager" {
  statement {
    effect = "Allow"

    actions = [
      "route53:GetChange"
    ]

    resources = ["arn:aws:route53:::change/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets"
    ]

    resources = ["arn:aws:route53:::hostedzone/*"]

  }

  statement {
    effect = "Allow"

    actions = [
      "route53:ListHostedZonesByName"
    ]

    resources = ["*"]

  }
}


resource "aws_iam_role" "eks-cert-manager-kiam" {
  name  = "tf-eks-${var.cluster-name}-cert-manager-kiam"
  count = local.cert_manager["enabled"] && local.cert_manager["create_iam_resources_kiam"] ? 1 : 0

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

resource "aws_iam_role_policy_attachment" "eks-cert-manager-kiam" {
  count      = local.cert_manager["enabled"] && local.cert_manager["create_iam_resources_kiam"] ? 1 : 0
  role       = aws_iam_role.eks-cert-manager-kiam[count.index].name
  policy_arn = aws_iam_policy.eks-cert-manager[count.index].arn
}

resource "kubernetes_namespace" "cert_manager" {
  count = local.cert_manager["enabled"] ? 1 : 0

  metadata {
    annotations = {
      "iam.amazonaws.com/permitted"           = "${local.cert_manager["create_iam_resources_kiam"] ? aws_iam_role.eks-cert-manager-kiam[0].arn : "^$"}"
      "certmanager.k8s.io/disable-validation" = "true"
    }

    labels = {
      name = local.cert_manager["namespace"]
    }

    name = local.cert_manager["namespace"]
  }
}

resource "helm_release" "cert_manager" {
  count                 = local.cert_manager["enabled"] ? 1 : 0
  repository            = local.cert_manager["repository"]
  name                  = local.cert_manager["name"]
  chart                 = local.cert_manager["chart"]
  version               = local.cert_manager["chart_version"]
  timeout               = local.cert_manager["timeout"]
  force_update          = local.cert_manager["force_update"]
  recreate_pods         = local.cert_manager["recreate_pods"]
  wait                  = local.cert_manager["wait"]
  atomic                = local.cert_manager["atomic"]
  cleanup_on_fail       = local.cert_manager["cleanup_on_fail"]
  dependency_update     = local.cert_manager["dependency_update"]
  disable_crd_hooks     = local.cert_manager["disable_crd_hooks"]
  disable_webhooks      = local.cert_manager["disable_webhooks"]
  render_subchart_notes = local.cert_manager["render_subchart_notes"]
  replace               = local.cert_manager["replace"]
  reset_values          = local.cert_manager["reset_values"]
  reuse_values          = local.cert_manager["reuse_values"]
  skip_crds             = local.cert_manager["skip_crds"]
  verify                = local.cert_manager["verify"]
  values = [
    local.values_cert_manager,
    local.cert_manager["extra_values"]
  ]
  namespace = kubernetes_namespace.cert_manager.*.metadata.0.name[count.index]

  depends_on = [
    helm_release.kiam,
    helm_release.prometheus_operator
  ]
}

data "kubectl_path_documents" "cert_manager_cluster_issuers" {
  pattern = "./templates/cert-manager-cluster-issuers.yaml"
  vars = {
    acme_email = local.cert_manager["acme_email"]
    aws_region = data.aws_region.current.name
  }
}

resource "kubectl_manifest" "cert_manager_cluster_issuers" {
  count      = (local.cert_manager["enabled"] ? 1 : 0) * (local.cert_manager["enable_default_cluster_issuers"] ? 1 : 0) * length(data.kubectl_path_documents.cert_manager_cluster_issuers.documents)
  yaml_body  = element(data.kubectl_path_documents.cert_manager_cluster_issuers.documents, count.index)
  depends_on = [helm_release.cert_manager]
}

resource "kubernetes_network_policy" "cert_manager_default_deny" {
  count = local.cert_manager["enabled"] && local.cert_manager["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.cert_manager.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.cert_manager.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "cert_manager_allow_namespace" {
  count = local.cert_manager["enabled"] && local.cert_manager["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.cert_manager.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.cert_manager.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.cert_manager.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "cert_manager_allow_monitoring" {
  count = local.cert_manager["enabled"] && local.cert_manager["default_network_policy"] && local.prometheus_operator["enabled"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.cert_manager.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.cert_manager.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      ports {
        port     = "9402"
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

resource "kubernetes_network_policy" "cert_manager_allow_control_plane" {
  count = local.cert_manager["enabled"] && local.cert_manager["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.cert_manager.*.metadata.0.name[count.index]}-allow-control-plane"
    namespace = kubernetes_namespace.cert_manager.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "app"
        operator = "In"
        values   = ["webhook"]
      }
    }

    ingress {
      ports {
        port     = "10250"
        protocol = "TCP"
      }

      dynamic "from" {
        for_each = local.cert_manager["allowed_cidrs"]
        content {
          ip_block {
            cidr = from.value
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

