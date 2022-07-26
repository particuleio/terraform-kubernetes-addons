locals {
  vault = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "vault")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "vault")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "vault")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "vault")].version
      namespace              = "vault"
      enabled                = false
      create_ns              = true
      default_network_policy = true
      generate_ca            = false
      trusted_ca_content     = null
    },
    var.vault
  )

  values_vault = <<-VALUES
    injector:
      replicas: 2
      metrics:
        enabled: ${local.kube-prometheus-stack.enabled}
      failurePolicy: Fail
      priorityClassName: ${local.priority-class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
    VALUES
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
  values = [
    local.values_vault,
    local.vault["extra_values"]
  ]
  namespace = local.vault["create_ns"] ? kubernetes_namespace.vault.*.metadata.0.name[count.index] : local.vault["namespace"]
}

resource "kubernetes_network_policy" "vault_default_deny" {
  count = local.vault["enabled"] && local.vault["create_ns"] && local.vault["default_network_policy"] ? 1 : 0

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
  count = local.vault["enabled"] && local.vault["create_ns"] && local.vault["default_network_policy"] ? 1 : 0

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
