locals {

  external_dns = merge(
    local.helm_defaults,
    {
      name                      = "external-dns"
      namespace                 = "external-dns"
      chart                     = "external-dns"
      repository                = "https://charts.bitnami.com/bitnami"
      service_account_name      = "external-dns"
      create_iam_resources_kiam = false
      create_iam_resources_irsa = true
      enabled                   = false
      chart_version             = "3.3.0"
      version                   = "0.7.3-debian-10-r0"
      iam_policy_override       = ""
      default_network_policy    = true
    },
    var.external_dns
  )

  values_external_dns = <<VALUES
image:
  tag: ${local.external_dns["version"]}
provider: aws
txtPrefix: "ext-dns-"
rbac:
 create: true
 pspEnabled: true
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: "${local.external_dns["enabled"] && local.external_dns["create_iam_resources_irsa"] ? module.iam_assumable_role_external_dns.this_iam_role_arn : ""}"
podAnnotations:
  iam.amazonaws.com/role: "${local.external_dns["enabled"] && local.external_dns["create_iam_resources_kiam"] ? aws_iam_role.eks-external-dns-kiam[0].arn : ""}"
metrics:
  enabled: ${local.prometheus_operator["enabled"]}
  serviceMonitor:
    enabled: ${local.prometheus_operator["enabled"]}
priorityClassName: ${local.priority_class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
VALUES
}

module "iam_assumable_role_external_dns" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v2.0"
  create_role                   = local.external_dns["enabled"] && local.external_dns["create_iam_resources_irsa"]
  role_name                     = "tf-eks-${var.cluster-name}-external-dns-irsa"
  provider_url                  = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns              = local.external_dns["enabled"] && local.external_dns["create_iam_resources_irsa"] ? [aws_iam_policy.eks-external-dns[0].arn] : []
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.external_dns["namespace"]}:${local.external_dns["service_account_name"]}"]
}

resource "aws_iam_policy" "eks-external-dns" {
  count  = local.external_dns["enabled"] && (local.external_dns["create_iam_resources_kiam"] || local.external_dns["create_iam_resources_irsa"]) ? 1 : 0
  name   = "tf-eks-${var.cluster-name}-external-dns"
  policy = local.external_dns["iam_policy_override"] == "" ? data.aws_iam_policy_document.external_dns.json : local.external_dns["iam_policy_override"]
}

data "aws_iam_policy_document" "external_dns" {
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

resource "aws_iam_role" "eks-external-dns-kiam" {
  name  = "terraform-eks-${var.cluster-name}-external-dns-kiam"
  count = local.external_dns["enabled"] && local.external_dns["create_iam_resources_kiam"] ? 1 : 0

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

resource "aws_iam_role_policy_attachment" "eks-external-dns-kiam" {
  count      = local.external_dns["enabled"] && local.external_dns["create_iam_resources_kiam"] ? 1 : 0
  role       = aws_iam_role.eks-external-dns-kiam[count.index].name
  policy_arn = aws_iam_policy.eks-external-dns[count.index].arn
}

resource "kubernetes_namespace" "external_dns" {
  count = local.external_dns["enabled"] ? 1 : 0

  metadata {
    annotations = {
      "iam.amazonaws.com/permitted" = "${local.external_dns["create_iam_resources_kiam"] ? aws_iam_role.eks-external-dns-kiam[0].arn : "^$"}"
    }

    labels = {
      name = local.external_dns["namespace"]
    }

    name = local.external_dns["namespace"]
  }
}

resource "helm_release" "external_dns" {
  count                 = local.external_dns["enabled"] ? 1 : 0
  repository            = local.external_dns["repository"]
  name                  = local.external_dns["name"]
  chart                 = local.external_dns["chart"]
  version               = local.external_dns["chart_version"]
  timeout               = local.external_dns["timeout"]
  force_update          = local.external_dns["force_update"]
  recreate_pods         = local.external_dns["recreate_pods"]
  wait                  = local.external_dns["wait"]
  atomic                = local.external_dns["atomic"]
  cleanup_on_fail       = local.external_dns["cleanup_on_fail"]
  dependency_update     = local.external_dns["dependency_update"]
  disable_crd_hooks     = local.external_dns["disable_crd_hooks"]
  disable_webhooks      = local.external_dns["disable_webhooks"]
  render_subchart_notes = local.external_dns["render_subchart_notes"]
  replace               = local.external_dns["replace"]
  reset_values          = local.external_dns["reset_values"]
  reuse_values          = local.external_dns["reuse_values"]
  skip_crds             = local.external_dns["skip_crds"]
  verify                = local.external_dns["verify"]
  values = [
    local.values_external_dns,
    local.external_dns["extra_values"]
  ]
  namespace = kubernetes_namespace.external_dns.*.metadata.0.name[count.index]

  depends_on = [
    helm_release.kiam,
    helm_release.prometheus_operator
  ]
}

resource "kubernetes_network_policy" "external_dns_default_deny" {
  count = local.external_dns["enabled"] && local.external_dns["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.external_dns.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.external_dns.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "external_dns_allow_namespace" {
  count = local.external_dns["enabled"] && local.external_dns["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.external_dns.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.external_dns.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.external_dns.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "external_dns_allow_monitoring" {
  count = local.external_dns["enabled"] && local.external_dns["default_network_policy"] && local.prometheus_operator["enabled"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.external_dns.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.external_dns.*.metadata.0.name[count.index]
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
