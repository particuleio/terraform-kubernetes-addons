locals {

  karpenter = merge(
    local.helm_defaults,
    {
      name                            = local.helm_dependencies[index(local.helm_dependencies.*.name, "karpenter")].name
      chart                           = local.helm_dependencies[index(local.helm_dependencies.*.name, "karpenter")].name
      repository                      = local.helm_dependencies[index(local.helm_dependencies.*.name, "karpenter")].repository
      chart_version                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "karpenter")].version
      namespace                       = "karpenter"
      enabled                         = false
      create_ns                       = true
      default_network_policy          = true
      irsa_oidc_provider_arn          = var.eks["oidc_provider_arn"]
      irsa_namespace_service_accounts = ["karpenter:karpenter"]
      allowed_cidrs                   = ["0.0.0.0/0"]
      iam_role_arn                    = ""
    },
    var.karpenter
  )

  karpenter-crd = merge(
    local.helm_defaults,
    {
      name          = local.helm_dependencies[index(local.helm_dependencies.*.name, "karpenter-crd")].name
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "karpenter-crd")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "karpenter-crd")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "karpenter-crd")].version
      namespace     = "karpenter"
      enabled       = local.karpenter.enabled
    },
    var.karpenter-crd
  )

  values_karpenter = <<-VALUES
    serviceMonitor:
      enabled: ${local.kube-prometheus-stack["enabled"] || local.victoria-metrics-k8s-stack["enabled"]}
    VALUES

}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.ecr_public
}

provider "aws" {
  region = "us-east-1"
  alias  = "ecr_public"
}

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 19.0"

  create = local.karpenter["enabled"]

  cluster_name = var.cluster-name

  irsa_use_name_prefix            = false
  irsa_oidc_provider_arn          = local.karpenter["irsa_oidc_provider_arn"]
  irsa_namespace_service_accounts = local.karpenter["irsa_namespace_service_accounts"]

  create_iam_role = false
  iam_role_arn    = local.karpenter["iam_role_arn"]

  tags = local.tags
}

resource "kubernetes_namespace" "karpenter" {
  count = local.karpenter["enabled"] && local.karpenter["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name = local.karpenter["namespace"]
    }

    name = local.karpenter["namespace"]
  }
}


resource "helm_release" "karpenter_crd" {
  count                 = local.karpenter-crd["enabled"] ? 1 : 0
  repository            = local.karpenter-crd["repository"]
  name                  = local.karpenter-crd["name"]
  chart                 = local.karpenter-crd["chart"]
  version               = local.karpenter-crd["chart_version"]
  timeout               = local.karpenter-crd["timeout"]
  force_update          = local.karpenter-crd["force_update"]
  recreate_pods         = local.karpenter-crd["recreate_pods"]
  wait                  = local.karpenter-crd["wait"]
  atomic                = local.karpenter-crd["atomic"]
  cleanup_on_fail       = local.karpenter-crd["cleanup_on_fail"]
  dependency_update     = local.karpenter-crd["dependency_update"]
  disable_crd_hooks     = local.karpenter-crd["disable_crd_hooks"]
  disable_webhooks      = local.karpenter-crd["disable_webhooks"]
  render_subchart_notes = local.karpenter-crd["render_subchart_notes"]
  replace               = local.karpenter-crd["replace"]
  reset_values          = local.karpenter-crd["reset_values"]
  reuse_values          = local.karpenter-crd["reuse_values"]
  skip_crds             = local.karpenter-crd["skip_crds"]
  verify                = local.karpenter-crd["verify"]

  namespace = kubernetes_namespace.karpenter.*.metadata.0.name[count.index]

}

resource "helm_release" "karpenter" {
  count                 = local.karpenter["enabled"] ? 1 : 0
  repository            = local.karpenter["repository"]
  repository_username   = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password   = data.aws_ecrpublic_authorization_token.token.password
  name                  = local.karpenter["name"]
  chart                 = local.karpenter["chart"]
  version               = local.karpenter["chart_version"]
  timeout               = local.karpenter["timeout"]
  force_update          = local.karpenter["force_update"]
  recreate_pods         = local.karpenter["recreate_pods"]
  wait                  = local.karpenter["wait"]
  atomic                = local.karpenter["atomic"]
  cleanup_on_fail       = local.karpenter["cleanup_on_fail"]
  dependency_update     = local.karpenter["dependency_update"]
  disable_crd_hooks     = local.karpenter["disable_crd_hooks"]
  disable_webhooks      = local.karpenter["disable_webhooks"]
  render_subchart_notes = local.karpenter["render_subchart_notes"]
  replace               = local.karpenter["replace"]
  reset_values          = local.karpenter["reset_values"]
  reuse_values          = local.karpenter["reuse_values"]
  skip_crds             = local.karpenter["skip_crds"]
  verify                = local.karpenter["verify"]
  values = [
    local.values_karpenter,
    local.karpenter["extra_values"]
  ]
  namespace = local.karpenter["create_ns"] ? kubernetes_namespace.karpenter.*.metadata.0.name[count.index] : local.karpenter["namespace"]

  depends_on = [
    helm_release.karpenter_crd
  ]

  set {
    name  = "settings.aws.clusterName"
    value = var.cluster-name
  }

  set {
    name  = "settings.aws.clusterEndpoint"
    value = var.eks["cluster_endpoint"]
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter.irsa_arn
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = module.karpenter.instance_profile_name
  }

  set {
    name  = "settings.aws.interruptionQueueName"
    value = module.karpenter.queue_name
  }
}

resource "kubernetes_network_policy" "karpenter_default_deny" {
  count = local.karpenter["create_ns"] && local.karpenter["enabled"] && local.karpenter["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.karpenter.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.karpenter.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "karpenter_allow_namespace" {
  count = local.karpenter["create_ns"] && local.karpenter["enabled"] && local.karpenter["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.karpenter.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.karpenter.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.karpenter.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "karpenter_allow_monitoring" {
  count = local.karpenter["create_ns"] && local.karpenter["enabled"] && local.karpenter["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.karpenter.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.karpenter.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      ports {
        port     = "8080"
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

resource "kubernetes_network_policy" "karpenter_allow_control_plane" {
  count = local.karpenter["create_ns"] && local.karpenter["enabled"] && local.karpenter["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.karpenter.*.metadata.0.name[count.index]}-allow-control-plane"
    namespace = kubernetes_namespace.karpenter.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "app.kubernetes.io/name"
        operator = "In"
        values   = ["karpenter"]
      }
    }

    ingress {
      ports {
        port     = "8443"
        protocol = "TCP"
      }

      dynamic "from" {
        for_each = local.karpenter["allowed_cidrs"]
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
