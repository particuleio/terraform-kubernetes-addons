locals {

  external_dns_secondary = merge(
    local.helm_defaults,
    {
      name                      = "external-dns-secondary"
      namespace                 = "external-dns-secondary"
      chart                     = "external-dns"
      repository                = "https://charts.bitnami.com/bitnami"
      service_account_name      = "external-dns-secondary"
      create_iam_resources_kiam = false
      create_iam_resources_irsa = true
      enabled                   = false
      chart_version             = "3.3.0"
      version                   = "0.7.3-debian-10-r0"
      iam_policy_override       = ""
      default_network_policy    = true
    },
    var.external_dns_secondary
  )

  values_external_dns_secondary = <<VALUES
image:
  tag: ${local.external_dns_secondary["version"]}
provider: aws
txtPrefix: "ext-dns-"
rbac:
 create: true
 pspEnabled: true
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: "${local.external_dns_secondary["enabled"] && local.external_dns_secondary["create_iam_resources_irsa"] ? module.iam_assumable_role_external_dns_secondary.this_iam_role_arn : ""}"
podAnnotations:
  iam.amazonaws.com/role: "${local.external_dns_secondary["enabled"] && local.external_dns_secondary["create_iam_resources_kiam"] ? aws_iam_role.eks-external-dns-secondary-kiam[0].arn : ""}"
metrics:
  enabled: ${local.prometheus_operator["enabled"]}
  serviceMonitor:
    enabled: ${local.prometheus_operator["enabled"]}
priorityClassName: ${local.priority_class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
VALUES
}

module "iam_assumable_role_external_dns_secondary" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v2.0"
  create_role                   = local.external_dns_secondary["enabled"] && local.external_dns_secondary["create_iam_resources_irsa"]
  role_name                     = "tf-eks-${var.cluster-name}-external-dns-secondary-irsa"
  provider_url                  = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns              = local.external_dns_secondary["enabled"] && local.external_dns_secondary["create_iam_resources_irsa"] ? [aws_iam_policy.eks-external-dns-secondary[0].arn] : []
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.external_dns_secondary["namespace"]}:${local.external_dns_secondary["service_account_name"]}"]
}

resource "aws_iam_policy" "eks-external-dns-secondary" {
  count  = local.external_dns_secondary["enabled"] && (local.external_dns_secondary["create_iam_resources_kiam"] || local.external_dns_secondary["create_iam_resources_irsa"]) ? 1 : 0
  name   = "tf-eks-${var.cluster-name}-external-dns-secondary"
  policy = local.external_dns_secondary["iam_policy_override"] == "" ? data.aws_iam_policy_document.external_dns_secondary.json : local.external_dns_secondary["iam_policy_override"]
}

data "aws_iam_policy_document" "external_dns_secondary" {
  statement {
    effect = "Allow"

    actions = [
      "route53:ChangeResourceRecordSets"
    ]

    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets"
    ]

    resources = ["*"]

  }
}

resource "aws_iam_role" "eks-external-dns-secondary-kiam" {
  name  = "terraform-eks-${var.cluster-name}-external-dns-secondary-kiam"
  count = local.external_dns_secondary["enabled"] && local.external_dns_secondary["create_iam_resources_kiam"] ? 1 : 0

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

resource "aws_iam_role_policy_attachment" "eks-external-dns-secondary-kiam" {
  count      = local.external_dns_secondary["enabled"] && local.external_dns_secondary["create_iam_resources_kiam"] ? 1 : 0
  role       = aws_iam_role.eks-external-dns-secondary-kiam[count.index].name
  policy_arn = aws_iam_policy.eks-external-dns-secondary[count.index].arn
}

resource "kubernetes_namespace" "external_dns_secondary" {
  count = local.external_dns_secondary["enabled"] ? 1 : 0

  metadata {
    annotations = {
      "iam.amazonaws.com/permitted" = "${local.external_dns_secondary["create_iam_resources_kiam"] ? aws_iam_role.eks-external-dns-secondary-kiam[0].arn : "^$"}"
    }

    labels = {
      name = local.external_dns_secondary["namespace"]
    }

    name = local.external_dns_secondary["namespace"]
  }
}

resource "helm_release" "external_dns_secondary" {
  count                 = local.external_dns_secondary["enabled"] ? 1 : 0
  repository            = local.external_dns_secondary["repository"]
  name                  = local.external_dns_secondary["name"]
  chart                 = local.external_dns_secondary["chart"]
  version               = local.external_dns_secondary["chart_version"]
  timeout               = local.external_dns_secondary["timeout"]
  force_update          = local.external_dns_secondary["force_update"]
  recreate_pods         = local.external_dns_secondary["recreate_pods"]
  wait                  = local.external_dns_secondary["wait"]
  atomic                = local.external_dns_secondary["atomic"]
  cleanup_on_fail       = local.external_dns_secondary["cleanup_on_fail"]
  dependency_update     = local.external_dns_secondary["dependency_update"]
  disable_crd_hooks     = local.external_dns_secondary["disable_crd_hooks"]
  disable_webhooks      = local.external_dns_secondary["disable_webhooks"]
  render_subchart_notes = local.external_dns_secondary["render_subchart_notes"]
  replace               = local.external_dns_secondary["replace"]
  reset_values          = local.external_dns_secondary["reset_values"]
  reuse_values          = local.external_dns_secondary["reuse_values"]
  skip_crds             = local.external_dns_secondary["skip_crds"]
  verify                = local.external_dns_secondary["verify"]
  values = [
    local.values_external_dns_secondary,
    local.external_dns_secondary["extra_values"]
  ]
  namespace = kubernetes_namespace.external_dns_secondary.*.metadata.0.name[count.index]

  depends_on = [
    helm_release.kiam,
    helm_release.prometheus_operator
  ]
}

resource "kubernetes_network_policy" "external_dns_secondary_default_deny" {
  count = local.external_dns_secondary["enabled"] && local.external_dns_secondary["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.external_dns_secondary.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.external_dns_secondary.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "external_dns_secondary_allow_namespace" {
  count = local.external_dns_secondary["enabled"] && local.external_dns_secondary["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.external_dns_secondary.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.external_dns_secondary.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.external_dns_secondary.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "external_dns_secondary_allow_monitoring" {
  count = local.external_dns_secondary["enabled"] && local.external_dns_secondary["default_network_policy"] && local.prometheus_operator["enabled"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.external_dns_secondary.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.external_dns_secondary.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      ports {
        port     = "http"
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
