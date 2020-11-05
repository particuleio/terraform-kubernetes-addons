locals {

  external-dns = merge(
    local.helm_defaults,
    {
      name                      = "external-dns"
      namespace                 = "external-dns"
      chart                     = "external-dns"
      repository                = "https://charts.bitnami.com/bitnami"
      service_account_name      = "external-dns"
      create_iam_resources_irsa = true
      enabled                   = false
      chart_version             = "3.6.0"
      version                   = "0.7.4-debian-10-r29"
      iam_policy_override       = ""
      default_network_policy    = true
    },
    var.external-dns
  )

  values_external-dns = <<VALUES
image:
  tag: ${local.external-dns["version"]}
provider: aws
aws:
  region: ${data.aws_region.current.name}
txtPrefix: "ext-dns-"
rbac:
 create: true
 pspEnabled: true
serviceAccount:
  name: ${local.external-dns["service_account_name"]}
  annotations:
    eks.amazonaws.com/role-arn: "${local.external-dns["enabled"] && local.external-dns["create_iam_resources_irsa"] ? module.iam_assumable_role_external-dns.this_iam_role_arn : ""}"
metrics:
  enabled: ${local.kube-prometheus-stack["enabled"]}
  serviceMonitor:
    enabled: ${local.kube-prometheus-stack["enabled"]}
priorityClassName: ${local.priority-class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
VALUES
}

module "iam_assumable_role_external-dns" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> 3.0"
  create_role                   = local.external-dns["enabled"] && local.external-dns["create_iam_resources_irsa"]
  role_name                     = "tf-${var.cluster-name}-${local.external-dns["name"]}-irsa"
  provider_url                  = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns              = local.external-dns["enabled"] && local.external-dns["create_iam_resources_irsa"] ? [aws_iam_policy.external-dns[0].arn] : []
  number_of_role_policy_arns    = 1
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.external-dns["namespace"]}:${local.external-dns["service_account_name"]}"]
}

resource "aws_iam_policy" "external-dns" {
  count  = local.external-dns["enabled"] && local.external-dns["create_iam_resources_irsa"] ? 1 : 0
  name   = "tf-${var.cluster-name}-${local.external-dns["name"]}"
  policy = local.external-dns["iam_policy_override"] == "" ? data.aws_iam_policy_document.external-dns.json : local.external-dns["iam_policy_override"]
}

data "aws_iam_policy_document" "external-dns" {
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

resource "kubernetes_namespace" "external-dns" {
  count = local.external-dns["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.external-dns["namespace"]
    }

    name = local.external-dns["namespace"]
  }
}

resource "helm_release" "external-dns" {
  count                 = local.external-dns["enabled"] ? 1 : 0
  repository            = local.external-dns["repository"]
  name                  = local.external-dns["name"]
  chart                 = local.external-dns["chart"]
  version               = local.external-dns["chart_version"]
  timeout               = local.external-dns["timeout"]
  force_update          = local.external-dns["force_update"]
  recreate_pods         = local.external-dns["recreate_pods"]
  wait                  = local.external-dns["wait"]
  atomic                = local.external-dns["atomic"]
  cleanup_on_fail       = local.external-dns["cleanup_on_fail"]
  dependency_update     = local.external-dns["dependency_update"]
  disable_crd_hooks     = local.external-dns["disable_crd_hooks"]
  disable_webhooks      = local.external-dns["disable_webhooks"]
  render_subchart_notes = local.external-dns["render_subchart_notes"]
  replace               = local.external-dns["replace"]
  reset_values          = local.external-dns["reset_values"]
  reuse_values          = local.external-dns["reuse_values"]
  skip_crds             = local.external-dns["skip_crds"]
  verify                = local.external-dns["verify"]
  values = [
    local.values_external-dns,
    local.external-dns["extra_values"]
  ]
  namespace = kubernetes_namespace.external-dns.*.metadata.0.name[count.index]

  depends_on = [
    helm_release.kube-prometheus-stack
  ]
}

resource "kubernetes_network_policy" "external-dns_default_deny" {
  count = local.external-dns["enabled"] && local.external-dns["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.external-dns.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.external-dns.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "external-dns_allow_namespace" {
  count = local.external-dns["enabled"] && local.external-dns["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.external-dns.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.external-dns.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.external-dns.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "external-dns_allow_monitoring" {
  count = local.external-dns["enabled"] && local.external-dns["default_network_policy"] && local.kube-prometheus-stack["enabled"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.external-dns.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.external-dns.*.metadata.0.name[count.index]
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
            name = kubernetes_namespace.kube-prometheus-stack.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
