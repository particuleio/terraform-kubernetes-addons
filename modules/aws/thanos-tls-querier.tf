locals {

  thanos-tls-querier = { for k, v in var.thanos-tls-querier : k => merge(
    local.helm_defaults,
    {
      chart              = local.helm_dependencies[index(local.helm_dependencies.*.name, "oci://registry-1.docker.io/bitnamicharts/thanos")].name
      repository         = local.helm_dependencies[index(local.helm_dependencies.*.name, "oci://registry-1.docker.io/bitnamicharts/thanos")].repository
      chart_version      = local.helm_dependencies[index(local.helm_dependencies.*.name, "oci://registry-1.docker.io/bitnamicharts/thanos")].version
      name               = "${local.thanos["name"]}-tls-querier-${k}"
      enabled            = false
      generate_cert      = local.thanos["generate_ca"]
      client_server_name = ""
      ## This default to Let's encrypt X1 root CA
      grpc_client_tls_ca_pem  = <<-EOV
        -----BEGIN CERTIFICATE-----
        MIIFazCCA1OgAwIBAgIRAIIQz7DSQONZRGPgu2OCiwAwDQYJKoZIhvcNAQELBQAw
        TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
        cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMTUwNjA0MTEwNDM4
        WhcNMzUwNjA0MTEwNDM4WjBPMQswCQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJu
        ZXQgU2VjdXJpdHkgUmVzZWFyY2ggR3JvdXAxFTATBgNVBAMTDElTUkcgUm9vdCBY
        MTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAK3oJHP0FDfzm54rVygc
        h77ct984kIxuPOZXoHj3dcKi/vVqbvYATyjb3miGbESTtrFj/RQSa78f0uoxmyF+
        0TM8ukj13Xnfs7j/EvEhmkvBioZxaUpmZmyPfjxwv60pIgbz5MDmgK7iS4+3mX6U
        A5/TR5d8mUgjU+g4rk8Kb4Mu0UlXjIB0ttov0DiNewNwIRt18jA8+o+u3dpjq+sW
        T8KOEUt+zwvo/7V3LvSye0rgTBIlDHCNAymg4VMk7BPZ7hm/ELNKjD+Jo2FR3qyH
        B5T0Y3HsLuJvW5iB4YlcNHlsdu87kGJ55tukmi8mxdAQ4Q7e2RCOFvu396j3x+UC
        B5iPNgiV5+I3lg02dZ77DnKxHZu8A/lJBdiB3QW0KtZB6awBdpUKD9jf1b0SHzUv
        KBds0pjBqAlkd25HN7rOrFleaJ1/ctaJxQZBKT5ZPt0m9STJEadao0xAH0ahmbWn
        OlFuhjuefXKnEgV4We0+UXgVCwOPjdAvBbI+e0ocS3MFEvzG6uBQE3xDk3SzynTn
        jh8BCNAw1FtxNrQHusEwMFxIt4I7mKZ9YIqioymCzLq9gwQbooMDQaHWBfEbwrbw
        qHyGO0aoSCqI3Haadr8faqU9GY/rOPNk3sgrDQoo//fb4hVC1CLQJ13hef4Y53CI
        rU7m2Ys6xt0nUW7/vGT1M0NPAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNV
        HRMBAf8EBTADAQH/MB0GA1UdDgQWBBR5tFnme7bl5AFzgAiIyBpY9umbbjANBgkq
        hkiG9w0BAQsFAAOCAgEAVR9YqbyyqFDQDLHYGmkgJykIrGF1XIpu+ILlaS/V9lZL
        ubhzEFnTIZd+50xx+7LSYK05qAvqFyFWhfFQDlnrzuBZ6brJFe+GnY+EgPbk6ZGQ
        3BebYhtF8GaV0nxvwuo77x/Py9auJ/GpsMiu/X1+mvoiBOv/2X/qkSsisRcOj/KK
        NFtY2PwByVS5uCbMiogziUwthDyC3+6WVwW6LLv3xLfHTjuCvjHIInNzktHCgKQ5
        ORAzI4JMPJ+GslWYHb4phowim57iaztXOoJwTdwJx4nLCgdNbOhdjsnvzqvHu7Ur
        TkXWStAmzOVyyghqpZXjFaH3pO3JLF+l+/+sKAIuvtd7u+Nxe5AW0wdeRlN8NwdC
        jNPElpzVmbUq4JUagEiuTDkHzsxHpFKVK7q4+63SM1N95R1NbdWhscdCb+ZAJzVc
        oyi3B43njTOQ5yOf+1CceWxG1bQVs5ZufpsMljq4Ui0/1lvh+wjChP4kqKOJ2qxq
        4RgqsahDYVvTH9w7jXbyLeiNdd8XM2w9U/t7y0Ff/9yi0GE44Za4rF2LN9d11TPA
        mRGunUHBcnWEvgJBQl9nJEiU0Zsnvgc/ubhPgXRR4Xq37Z0j4r7g1SgEEzwxA57d
        emyPxgcYxn/eR44/KJ4EBs+lVDR3veyJm+kXQ99b21/+jh5Xos1AnX5iItreGCc=
        -----END CERTIFICATE-----
        EOV
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
                enabled: ${v["generate_cert"]}
                key: |
                  ${indent(10, v["generate_cert"] ? tls_private_key.thanos-tls-querier-cert-key[k].private_key_pem : "")}
                cert: |
                  ${indent(10, v["generate_cert"] ? tls_locally_signed_cert.thanos-tls-querier-cert[k].cert_pem : "")}
                ca: |
                  ${indent(10, v["generate_cert"] ? v["grpc_client_tls_ca_pem"] : "")}
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
  ca_private_key_pem = tls_private_key.thanos-tls-querier-ca-key[0].private_key_pem
  ca_cert_pem        = tls_self_signed_cert.thanos-tls-querier-ca-cert[0].cert_pem

  validity_period_hours = 8760
  early_renewal_hours   = 720

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth"
  ]
}
