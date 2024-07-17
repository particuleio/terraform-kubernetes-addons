locals {
  loki-stack = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "loki")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "loki")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "loki")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "loki")].version
      namespace              = "monitoring"
      create_ns              = false
      enabled                = false
      default_network_policy = true
      create_bucket          = true
      bucket                 = "loki-store-${var.cluster-name}"
      bucket_region          = local.scaleway["region"]
      generate_ca            = true
      trusted_ca_content     = null
      create_promtail_cert   = true
      create_grafana_ds_cm   = true
    },
    var.loki-stack
  )

  values_loki-stack = <<-VALUES
    global
      dnsService: coredns
    serviceMonitor:
      enabled: ${local.kube-prometheus-stack["enabled"] || local.victoria-metrics-k8s-stack["enabled"]}
    priorityClassName: ${local.priority-class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
    persistence:
      enabled: true
    loki:
      auth_enabled: false
      storage:
        bucketNames:
          chunks: "${local.loki-stack["bucket"]}"
          ruler: "${local.loki-stack["bucket"]}"
          admin: "${local.loki-stack["bucket"]}"
        s3:
          region: eu-west-1
      schemaConfig:
        configs:
        - from: 2020-10-24
          store: boltdb-shipper
          object_store: aws
          schema: v12
          index:
            prefix: loki_index_
            period: 24h
      storage_config:
        aws:
          bucketnames: ${local.loki-stack["bucket"]}
          endpoint: s3.${local.loki-stack["bucket_region"]}.scw.cloud
          region: ${local.loki-stack["bucket_region"]}
          access_key_id: ${local.scaleway["scw_access_key"]}
          secret_access_key: ${local.scaleway["scw_secret_key"]}
    VALUES
}

resource "kubernetes_namespace" "loki-stack" {
  count = local.loki-stack["enabled"] && local.loki-stack["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name                               = local.loki-stack["namespace"]
      "${local.labels_prefix}/component" = "monitoring"
    }

    name = local.loki-stack["namespace"]
  }
}

resource "kubernetes_config_map" "loki-stack_grafana_ds" {
  count = local.loki-stack["enabled"] && local.loki-stack["create_grafana_ds_cm"] ? 1 : 0
  metadata {
    name      = "${local.loki-stack["name"]}-grafana-ds"
    namespace = local.loki-stack["namespace"]
    labels = {
      grafana_datasource = "1"
    }
  }

  data = {
    "datasource.yml" = <<-VALUES
      datasources:
      - access: proxy
        editable: true
        isDefault: false
        name: Loki
        orgId: 1
        type: loki
        url: http://${local.loki-stack["name"]}-gateway
        version: 1
      VALUES
  }
}


resource "helm_release" "loki-stack" {
  count                 = local.loki-stack["enabled"] ? 1 : 0
  repository            = local.loki-stack["repository"]
  name                  = local.loki-stack["name"]
  chart                 = local.loki-stack["chart"]
  version               = local.loki-stack["chart_version"]
  timeout               = local.loki-stack["timeout"]
  force_update          = local.loki-stack["force_update"]
  recreate_pods         = local.loki-stack["recreate_pods"]
  wait                  = local.loki-stack["wait"]
  atomic                = local.loki-stack["atomic"]
  cleanup_on_fail       = local.loki-stack["cleanup_on_fail"]
  dependency_update     = local.loki-stack["dependency_update"]
  disable_crd_hooks     = local.loki-stack["disable_crd_hooks"]
  disable_webhooks      = local.loki-stack["disable_webhooks"]
  render_subchart_notes = local.loki-stack["render_subchart_notes"]
  replace               = local.loki-stack["replace"]
  reset_values          = local.loki-stack["reset_values"]
  reuse_values          = local.loki-stack["reuse_values"]
  skip_crds             = local.loki-stack["skip_crds"]
  verify                = local.loki-stack["verify"]
  values = [
    local.values_loki-stack,
    local.loki-stack["extra_values"]
  ]
  namespace = local.loki-stack["create_ns"] ? kubernetes_namespace.loki-stack.*.metadata.0.name[count.index] : local.loki-stack["namespace"]

  depends_on = [
    kubectl_manifest.prometheus-operator_crds
  ]
}

resource "tls_private_key" "loki-stack-ca-key" {
  count       = local.loki-stack["enabled"] && local.loki-stack["generate_ca"] ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "loki-stack-ca-cert" {
  count             = local.loki-stack["enabled"] && local.loki-stack["generate_ca"] ? 1 : 0
  private_key_pem   = tls_private_key.loki-stack-ca-key[0].private_key_pem
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

resource "kubernetes_network_policy" "loki-stack_default_deny" {
  count = local.loki-stack["create_ns"] && local.loki-stack["enabled"] && local.loki-stack["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.loki-stack.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.loki-stack.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "loki-stack_allow_namespace" {
  count = local.loki-stack["create_ns"] && local.loki-stack["enabled"] && local.loki-stack["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.loki-stack.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.loki-stack.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.loki-stack.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "loki-stack_allow_ingress" {
  count = local.loki-stack["create_ns"] && local.loki-stack["enabled"] && local.loki-stack["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.loki-stack.*.metadata.0.name[count.index]}-allow-ingress"
    namespace = kubernetes_namespace.loki-stack.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "${local.labels_prefix}/component" = "ingress"
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_secret" "loki-stack-ca" {
  count = local.loki-stack["enabled"] && (local.loki-stack["generate_ca"] || local.loki-stack["trusted_ca_content"] != null) ? 1 : 0
  metadata {
    name      = "${local.loki-stack["name"]}-ca"
    namespace = local.loki-stack["create_ns"] ? kubernetes_namespace.loki-stack.*.metadata.0.name[count.index] : local.loki-stack["namespace"]
  }

  data = {
    "ca.crt" = local.loki-stack["generate_ca"] ? tls_self_signed_cert.loki-stack-ca-cert[count.index].cert_pem : local.loki-stack["trusted_ca_content"]
  }
}

resource "scaleway_object_bucket" "loki_bucket" {
  count = local.loki-stack["enabled"] && local.loki-stack["create_bucket"] ? 1 : 0
  name  = local.loki-stack["bucket"]
  acl   = "private"
}

resource "tls_private_key" "promtail-key" {
  count       = local.loki-stack["enabled"] && local.loki-stack["generate_ca"] && local.loki-stack["create_promtail_cert"] ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "promtail-csr" {
  count           = local.loki-stack["enabled"] && local.loki-stack["generate_ca"] && local.loki-stack["create_promtail_cert"] ? 1 : 0
  private_key_pem = tls_private_key.promtail-key[count.index].private_key_pem

  subject {
    common_name = "promtail"
  }

  dns_names = [
    "promtail"
  ]
}

resource "tls_locally_signed_cert" "promtail-cert" {
  count              = local.loki-stack["enabled"] && local.loki-stack["generate_ca"] && local.loki-stack["create_promtail_cert"] ? 1 : 0
  cert_request_pem   = tls_cert_request.promtail-csr[count.index].cert_request_pem
  ca_private_key_pem = tls_private_key.loki-stack-ca-key[count.index].private_key_pem
  ca_cert_pem        = tls_self_signed_cert.loki-stack-ca-cert[count.index].cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth"
  ]
}

output "loki-stack-ca" {
  value = element(concat(tls_self_signed_cert.loki-stack-ca-cert[*].cert_pem, [""]), 0)
}

output "promtail-key" {
  value     = element(concat(tls_private_key.promtail-key[*].private_key_pem, [""]), 0)
  sensitive = true
}

output "promtail-cert" {
  value     = element(concat(tls_locally_signed_cert.promtail-cert[*].cert_pem, [""]), 0)
  sensitive = true
}
