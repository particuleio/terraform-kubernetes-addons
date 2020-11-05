locals {

  flux = merge(
    local.helm_defaults,
    {
      name                      = "flux"
      namespace                 = "flux"
      chart                     = "flux"
      repository                = "https://charts.fluxcd.io"
      service_account_name      = "flux"
      create_iam_resources_kiam = false
      create_iam_resources_irsa = true
      enabled                   = false
      chart_version             = "1.5.0"
      version                   = "1.20.2"
      default_network_policy    = true
    },
    var.flux
  )

  values_flux = <<VALUES
image:
  tag: ${local.flux["version"]}
rbac:
  create: true
  pspEnabled: true
syncGarbageCollection:
  enabled: true
  dry: false
annotations:
  iam.amazonaws.com/role: "${local.flux["enabled"] && local.flux["create_iam_resources_kiam"] ? aws_iam_role.eks-flux-kiam[0].arn : ""}"
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: "${local.flux["enabled"] && local.flux["create_iam_resources_irsa"] ? module.iam_assumable_role_flux.this_iam_role_arn : ""}"
prometheus:
  enabled: ${local.prometheus_operator["enabled"]}
  serviceMonitor:
    create: ${local.prometheus_operator["enabled"]}
VALUES
}

module "iam_assumable_role_flux" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v2.0"
  create_role                   = local.flux["enabled"] && local.flux["create_iam_resources_irsa"]
  role_name                     = "tf-eks-${var.cluster-name}-flux-irsa"
  provider_url                  = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns              = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.flux["namespace"]}:${local.flux["service_account_name"]}"]
}

resource "aws_iam_role" "eks-flux-kiam" {
  name  = "tf-eks-${var.cluster-name}-flux-kiam"
  count = local.flux["enabled"] && local.flux["create_iam_resources_kiam"] ? 1 : 0

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

resource "aws_iam_role_policy_attachment" "eks-flux-kiam" {
  count      = local.flux["enabled"] && local.flux["create_iam_resources_kiam"] ? 1 : 0
  role       = aws_iam_role.eks-flux-kiam[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "kubernetes_namespace" "flux" {
  count = local.flux["enabled"] ? 1 : 0

  metadata {
    annotations = {
      "iam.amazonaws.com/permitted" = "${local.flux["create_iam_resources_kiam"] ? aws_iam_role.eks-flux-kiam[0].arn : "^$"}"
    }

    labels = {
      name = local.flux["namespace"]
    }

    name = local.flux["namespace"]
  }
}

resource "kubernetes_role" "flux" {
  count = local.flux["enabled"] ? 1 : 0

  metadata {
    name      = "flux-${kubernetes_namespace.flux.*.metadata.0.name[count.index]}"
    namespace = kubernetes_namespace.flux.*.metadata.0.name[count.index]
  }

  rule {
    api_groups = ["", "batch", "extensions", "apps"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_role_binding" "flux" {
  count = local.flux["enabled"] ? 1 : 0

  metadata {
    name      = "flux-${kubernetes_namespace.flux.*.metadata.0.name[count.index]}-binding"
    namespace = kubernetes_namespace.flux.*.metadata.0.name[count.index]
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.flux.*.metadata.0.name[count.index]
  }

  subject {
    kind      = "ServiceAccount"
    name      = "flux"
    namespace = "flux"
  }
}

resource "helm_release" "flux" {
  count                 = local.flux["enabled"] ? 1 : 0
  repository            = local.flux["repository"]
  name                  = local.flux["name"]
  chart                 = local.flux["chart"]
  version               = local.flux["chart_version"]
  timeout               = local.flux["timeout"]
  force_update          = local.flux["force_update"]
  recreate_pods         = local.flux["recreate_pods"]
  wait                  = local.flux["wait"]
  atomic                = local.flux["atomic"]
  cleanup_on_fail       = local.flux["cleanup_on_fail"]
  dependency_update     = local.flux["dependency_update"]
  disable_crd_hooks     = local.flux["disable_crd_hooks"]
  disable_webhooks      = local.flux["disable_webhooks"]
  render_subchart_notes = local.flux["render_subchart_notes"]
  replace               = local.flux["replace"]
  reset_values          = local.flux["reset_values"]
  reuse_values          = local.flux["reuse_values"]
  skip_crds             = local.flux["skip_crds"]
  verify                = local.flux["verify"]
  values = [
    local.values_flux,
    local.flux["extra_values"]
  ]
  namespace = kubernetes_namespace.flux.*.metadata.0.name[count.index]

  depends_on = [
    helm_release.kiam,
    helm_release.prometheus_operator
  ]
}

resource "kubernetes_network_policy" "flux_default_deny" {
  count = local.flux["enabled"] && local.flux["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.flux.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.flux.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "flux_allow_namespace" {
  count = local.flux["enabled"] && local.flux["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.flux.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.flux.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.flux.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "flux_allow_monitoring" {
  count = local.flux["enabled"] && local.flux["default_network_policy"] && local.prometheus_operator["enabled"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.flux.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.flux.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      ports {
        port     = "3030"
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

output flux-role-arn-kiam {
  value = aws_iam_role.eks-flux-kiam.*.arn
}

output flux-role-name-kiam {
  value = aws_iam_role.eks-flux-kiam.*.name
}

output flux-role-arn-irsa {
  value = module.iam_assumable_role_flux.this_iam_role_arn
}

output flux-role-name-irsa {
  value = module.iam_assumable_role_flux.this_iam_role_name
}
