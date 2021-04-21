locals {
  vault = merge(
    local.helm_defaults,
    {
      name                      = local.helm_dependencies[index(local.helm_dependencies.*.name, "vault")].name
      chart                     = local.helm_dependencies[index(local.helm_dependencies.*.name, "vault")].name
      repository                = local.helm_dependencies[index(local.helm_dependencies.*.name, "vault")].repository
      chart_version             = local.helm_dependencies[index(local.helm_dependencies.*.name, "vault")].version
      namespace                 = "vault"
      service_account_name      = "vault"
      create_iam_resources_irsa = true
      enabled                   = false
      create_ns                 = true
      default_network_policy    = true
      create_kms_key            = true
      existing_kms_key_arn      = null
      override_kms_alias        = null
      allowed_cidrs             = ["0.0.0.0/0"]
      iam_policy_override       = null
      use_kms                   = true
    },
    var.vault
  )

  values_vault_no_kms = <<-VALUES
    injector:
      replicas: 2
      metrics:
        enabled: ${local.kube-prometheus-stack.enabled}
      failurePolicy: Fail
      priorityClassName: ${local.priority-class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
  VALUES

  values_vault = <<-VALUES
    injector:
      replicas: 2
      metrics:
        enabled: ${local.kube-prometheus-stack.enabled}
      failurePolicy: Fail
      priorityClassName: ${local.priority-class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
    server:
      auditStorage:
        enabled: true
      serviceAccount:
        name: ${local.vault["service_account_name"]}
        annotations:
          eks.amazonaws.com/role-arn: "${local.vault["enabled"] && local.vault["create_iam_resources_irsa"] ? module.iam_assumable_role_vault.this_iam_role_arn : ""}"
        updateStrategyType: "RollingUpdate"
      priorityClassName: ${local.priority-class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
      ha:
        enabled: true
        replicas: 3
        raft:
          enabled: true
          setNodeId: true
          config: |
            ui = true
            listener "tcp" {
              tls_disable = 1
              address = "[::]:8200"
              cluster_address = "[::]:8201"
            }
            storage "raft" {
              path       = "/vault/data"
              retry_join = {
                leader_api_addr = "http://vault-0.vault-internal:8200"
              }
              retry_join = {
                leader_api_addr = "http://vault-1.vault-internal:8200"
              }
              retry_join = {
                leader_api_addr = "http://vault-2.vault-internal:8200"
              }
            }
            service_registration "kubernetes" {}
            seal "awskms" {
              region     = "${local.vault.enabled && local.vault.use_kms ? local.vault.create_kms_key ? data.aws_region.current.name : element(split(":", local.vault.existing_kms_key_arn), 3) : ""}"
              kms_key_id = "${local.vault.enabled && local.vault.use_kms ? local.vault.create_kms_key ? aws_kms_key.vault.0.id : element(split("/", local.vault.existing_kms_key_arn), 1) : ""}"
            }
    VALUES
}

module "iam_assumable_role_vault" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> 3.0"
  create_role                   = local.vault["enabled"] && local.vault["create_iam_resources_irsa"] && local.vault["use_kms"]
  role_name                     = "tf-${var.cluster-name}-${local.vault["name"]}-irsa"
  provider_url                  = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns              = local.vault["enabled"] && local.vault["create_iam_resources_irsa"] && local.vault.use_kms ? [aws_iam_policy.vault[0].arn] : []
  number_of_role_policy_arns    = 1
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.vault["namespace"]}:${local.vault["service_account_name"]}"]
  tags                          = local.tags
}

resource "aws_iam_policy" "vault" {
  count  = local.vault["enabled"] && local.vault["create_iam_resources_irsa"] && local.vault.use_kms ? 1 : 0
  name   = "tf-${var.cluster-name}-${local.vault["name"]}"
  policy = local.vault["iam_policy_override"] == null ? data.aws_iam_policy_document.vault.0.json : local.vault["iam_policy_override"]
}

data "aws_iam_policy_document" "vault" {
  count = local.vault.enabled && local.vault["create_iam_resources_irsa"] && local.vault.use_kms ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey"
    ]

    resources = [local.vault.create_kms_key ? aws_kms_key.vault.0.arn : local.vault.existing_kms_key_arn]
  }
}

resource "aws_kms_key" "vault" {
  count = local.vault.enabled && local.vault.use_kms && local.vault.create_kms_key ? 1 : 0
}

resource "aws_kms_alias" "vault" {
  count         = local.vault.enabled && local.vault.use_kms && local.vault.create_kms_key ? 1 : 0
  name          = "alias/vault-${local.vault.override_kms_alias != null ? local.vault.override_kms_alias : var.cluster-name}"
  target_key_id = aws_kms_key.vault.0.id
}

resource "kubernetes_namespace" "vault" {
  count = local.vault["enabled"] && local.vault["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name = local.vault["namespace"]
    }

    name = local.vault["namespace"]
  }
}

resource "helm_release" "vault" {
  count                 = local.vault["enabled"] ? 1 : 0
  repository            = local.vault["repository"]
  name                  = local.vault["name"]
  chart                 = local.vault["chart"]
  version               = local.vault["chart_version"]
  timeout               = local.vault["timeout"]
  force_update          = local.vault["force_update"]
  recreate_pods         = local.vault["recreate_pods"]
  wait                  = local.vault["wait"]
  atomic                = local.vault["atomic"]
  cleanup_on_fail       = local.vault["cleanup_on_fail"]
  dependency_update     = local.vault["dependency_update"]
  disable_crd_hooks     = local.vault["disable_crd_hooks"]
  disable_webhooks      = local.vault["disable_webhooks"]
  render_subchart_notes = local.vault["render_subchart_notes"]
  replace               = local.vault["replace"]
  reset_values          = local.vault["reset_values"]
  reuse_values          = local.vault["reuse_values"]
  skip_crds             = local.vault["skip_crds"]
  verify                = local.vault["verify"]
  values = compact([
    local.vault.use_kms ? local.values_vault : local.values_vault_no_kms,
    local.vault["extra_values"]
  ])
  namespace = local.vault["create_ns"] ? kubernetes_namespace.vault.*.metadata.0.name[count.index] : local.vault["namespace"]
}

resource "kubernetes_network_policy" "vault_default_deny" {
  count = local.vault["enabled"] && local.vault["default_network_policy"] && local.vault.create_ns ? 1 : 0

  metadata {
    name      = "${local.vault["namespace"]}-${local.vault["name"]}-default-deny"
    namespace = local.vault["namespace"]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "vault_allow_namespace" {
  count = local.vault["enabled"] && local.vault["default_network_policy"] && local.vault.create_ns ? 1 : 0

  metadata {
    name      = "${local.vault["namespace"]}-${local.vault["name"]}-default-namespace"
    namespace = local.vault["namespace"]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = local.vault["namespace"]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "vault_allow_control_plane" {
  count = local.vault["enabled"] && local.vault["default_network_policy"] && local.vault.create_ns ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.vault.*.metadata.0.name[count.index]}-allow-control-plane"
    namespace = kubernetes_namespace.vault.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "app.kubernetes.io/name"
        operator = "In"
        values   = ["${local.vault["name"]}-agent-injector"]
      }
    }

    ingress {
      ports {
        port     = "8080"
        protocol = "TCP"
      }

      dynamic "from" {
        for_each = local.vault["allowed_cidrs"]
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
