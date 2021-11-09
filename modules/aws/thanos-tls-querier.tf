locals {

  thanos-tls-querier = { for k, v in var.thanos-tls-querier : k => merge(
    local.helm_defaults,
    {
      chart                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "thanos")].name
      repository              = local.helm_dependencies[index(local.helm_dependencies.*.name, "thanos")].repository
      chart_version           = local.helm_dependencies[index(local.helm_dependencies.*.name, "thanos")].version
      name                    = "${local.thanos["name"]}-tls-querier-${k}"
      enabled                 = false
      generate_cert           = local.thanos["generate_ca"]
      client_server_name      = ""
      stores                  = []
      default_global_requests = false
      default_global_limits   = false
    },
    v,
  ) }

  values_thanos-tls-querier = { for k, v in local.thanos-tls-querier : k => merge(
    {
      values = <<-VALUES
        metrics:
          enabled: true
          serviceMonitor:
            enabled: ${local.kube-prometheus-stack["enabled"] ? "true" : "false"}
        query:
          replicaCount: 2
          extraFlags:
            - --query.timeout=5m
            - --query.lookback-delta=15m
            - --query.replica-label=rule_replica
          enabled: true
          dnsDiscovery:
            enabled: false
          pdb:
            create: true
            minAvailable: 1
          grpc:
            client:
              servername: ${v["client_server_name"]}
              tls:
                enabled: true
                key: |
                  ${indent(10, v["generate_cert"] ? tls_private_key.thanos-tls-querier-cert-key[k].private_key_pem : "")}
                cert: |
                  ${indent(10, v["generate_cert"] ? tls_locally_signed_cert.thanos-tls-querier-cert[k].cert_pem : "")}
          stores: ${jsonencode(v["stores"])}
        queryFrontend:
          enabled: false
        compactor:
          enabled: false
        storegateway:
          enabled: false
        VALUES
    },
    v,
  ) }
}

resource "helm_release" "thanos-tls-querier" {
  for_each              = { for k, v in local.thanos-tls-querier : k => v if v["enabled"] }
  repository            = each.value["repository"]
  name                  = each.value["name"]
  chart                 = each.value["chart"]
  version               = each.value["chart_version"]
  timeout               = each.value["timeout"]
  force_update          = each.value["force_update"]
  recreate_pods         = each.value["recreate_pods"]
  wait                  = each.value["wait"]
  atomic                = each.value["atomic"]
  cleanup_on_fail       = each.value["cleanup_on_fail"]
  dependency_update     = each.value["dependency_update"]
  disable_crd_hooks     = each.value["disable_crd_hooks"]
  disable_webhooks      = each.value["disable_webhooks"]
  render_subchart_notes = each.value["render_subchart_notes"]
  replace               = each.value["replace"]
  reset_values          = each.value["reset_values"]
  reuse_values          = each.value["reuse_values"]
  skip_crds             = each.value["skip_crds"]
  verify                = each.value["verify"]
  values = compact([
    local.values_thanos-tls-querier[each.key]["values"],
    each.value["default_global_requests"] ? local.values_thanos_global_requests : null,
    each.value["default_global_limits"] ? local.values_thanos_global_limits : null,
    each.value["extra_values"]
  ])
  namespace = local.thanos["create_ns"] ? kubernetes_namespace.thanos.*.metadata.0.name[0] : local.thanos["namespace"]

  depends_on = [
    helm_release.kube-prometheus-stack,
  ]
}

resource "tls_private_key" "thanos-tls-querier-cert-key" {
  for_each    = { for k, v in local.thanos-tls-querier : k => v if v["enabled"] && v["generate_cert"] }
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "thanos-tls-querier-cert-csr" {
  for_each        = { for k, v in local.thanos-tls-querier : k => v if v["enabled"] && v["generate_cert"] }
  key_algorithm   = "ECDSA"
  private_key_pem = tls_private_key.thanos-tls-querier-cert-key[each.key].private_key_pem

  subject {
    common_name = each.key
  }

  dns_names = [
    each.key
  ]
}

resource "tls_locally_signed_cert" "thanos-tls-querier-cert" {
  for_each           = { for k, v in local.thanos-tls-querier : k => v if v["enabled"] && v["generate_cert"] }
  cert_request_pem   = tls_cert_request.thanos-tls-querier-cert-csr[each.key].cert_request_pem
  ca_key_algorithm   = "ECDSA"
  ca_private_key_pem = tls_private_key.thanos-tls-querier-ca-key[0].private_key_pem
  ca_cert_pem        = tls_self_signed_cert.thanos-tls-querier-ca-cert[0].cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth"
  ]
}
