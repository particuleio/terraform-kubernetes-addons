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
      kms_enable_key_rotation   = true
      generate_ca               = false
      trusted_ca_content        = null
      name_prefix               = "${var.cluster-name}-vault"
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
          eks.amazonaws.com/role-arn: "${local.vault["enabled"] && local.vault["create_iam_resources_irsa"] ? module.iam_assumable_role_vault.iam_role_arn : ""}"
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
                leader_api_addr = "http://${local.vault.name}-0.${local.vault.name}-internal:8200"
              }
              retry_join = {
                leader_api_addr = "http://${local.vault.name}-1.${local.vault.name}-internal:8200"
              }
              retry_join = {
                leader_api_addr = "http://${local.vault.name}-2.${local.vault.name}-internal:8200"
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
  version                       = "~> 5.0"
  create_role                   = local.vault["enabled"] && local.vault["create_iam_resources_irsa"] && local.vault["use_kms"]
  role_name                     = local.vault["name_prefix"]
  provider_url                  = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns              = local.vault["enabled"] && local.vault["create_iam_resources_irsa"] && local.vault.use_kms ? [aws_iam_policy.vault[0].arn] : []
  number_of_role_policy_arns    = 1
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.vault["namespace"]}:${local.vault["service_account_name"]}"]
  tags                          = local.tags
}

resource "aws_iam_policy" "vault" {
  count  = local.vault["enabled"] && local.vault["create_iam_resources_irsa"] && local.vault.use_kms ? 1 : 0
  name   = local.vault["name_prefix"]
  policy = local.vault["iam_policy_override"] == null ? data.aws_iam_policy_document.vault.0.json : local.vault["iam_policy_override"]
  tags   = local.tags
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
  count               = local.vault.enabled && local.vault.use_kms && local.vault.create_kms_key ? 1 : 0
  tags                = local.tags
  enable_key_rotation = local.vault.kms_enable_key_rotation
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

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels,
    ]
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

resource "tls_private_key" "vault-tls-ca-key" {
  count       = local.vault["generate_ca"] ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "vault-tls-ca-cert" {
  count             = local.vault["generate_ca"] ? 1 : 0
  key_algorithm     = "ECDSA"
  private_key_pem   = tls_private_key.vault-tls-ca-key[0].private_key_pem
  is_ca_certificate = true

  subject {
    common_name  = var.cluster-name
    organization = var.cluster-name
  }

  validity_period_hours = 87600

  allowed_uses = [
    "cert_signing"
  ]
}

resource "tls_private_key" "vault-tls-client-key" {
  count       = local.vault["generate_ca"] ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "vault-tls-client-csr" {
  count           = local.vault["generate_ca"] ? 1 : 0
  key_algorithm   = "ECDSA"
  private_key_pem = tls_private_key.vault-tls-client-key[count.index].private_key_pem

  subject {
    common_name = "vault-tls-client"
  }

  dns_names = [
    "vault-tls-client"
  ]
}

resource "tls_locally_signed_cert" "vault-tls-client-cert" {
  count              = local.vault["generate_ca"] ? 1 : 0
  cert_request_pem   = tls_cert_request.vault-tls-client-csr[count.index].cert_request_pem
  ca_key_algorithm   = "ECDSA"
  ca_private_key_pem = tls_private_key.vault-tls-ca-key[count.index].private_key_pem
  ca_cert_pem        = tls_self_signed_cert.vault-tls-ca-cert[count.index].cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth"
  ]
}

resource "kubernetes_secret" "vault-ca" {
  count = local.vault["enabled"] && (local.vault["generate_ca"] || local.vault["trusted_ca_content"] != null) ? 1 : 0
  metadata {
    name      = "${local.vault["name"]}-ca"
    namespace = local.vault["create_ns"] ? kubernetes_namespace.vault.*.metadata.0.name[count.index] : local.vault["namespace"]
  }

  data = {
    "ca.crt" = local.vault["generate_ca"] ? tls_self_signed_cert.vault-tls-ca-cert[count.index].cert_pem : local.vault["trusted_ca_content"]
  }
}

output "vault_ca_pem" {
  value = element(concat(tls_self_signed_cert.vault-tls-ca-cert[*].cert_pem, [""]), 0)
}


output "vault_ca_key" {
  value     = element(concat(tls_private_key.vault-tls-ca-key[*].private_key_pem, [""]), 0)
  sensitive = true
}

output "vault_tls_client_cert_pem" {
  value = element(concat(tls_locally_signed_cert.vault-tls-client-cert[*].cert_pem, [""]), 0)
}


output "vault_tls_client_key" {
  value     = element(concat(tls_private_key.vault-tls-client-key[*].private_key_pem, [""]), 0)
  sensitive = true
}
