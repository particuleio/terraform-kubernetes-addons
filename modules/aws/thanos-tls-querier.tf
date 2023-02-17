locals {

  thanos-tls-querier = { for k, v in var.thanos-tls-querier : k => merge(
    local.helm_defaults,
    {
      chart              = local.helm_dependencies[index(local.helm_dependencies.*.name, "thanos")].name
      repository         = local.helm_dependencies[index(local.helm_dependencies.*.name, "thanos")].repository
      chart_version      = local.helm_dependencies[index(local.helm_dependencies.*.name, "thanos")].version
      name               = "${local.thanos["name"]}-tls-querier-${k}"
      enabled            = false
      generate_cert      = local.thanos["generate_ca"]
      client_server_name = ""
      ## This default to Let's encrypt R3 CA
      grpc_client_tls_ca_pem  = <<-EOV
        -----BEGIN CERTIFICATE-----
        MIIFFjCCAv6gAwIBAgIRAJErCErPDBinU/bWLiWnX1owDQYJKoZIhvcNAQELBQAw
        TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
        cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMjAwOTA0MDAwMDAw
        WhcNMjUwOTE1MTYwMDAwWjAyMQswCQYDVQQGEwJVUzEWMBQGA1UEChMNTGV0J3Mg
        RW5jcnlwdDELMAkGA1UEAxMCUjMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
        AoIBAQC7AhUozPaglNMPEuyNVZLD+ILxmaZ6QoinXSaqtSu5xUyxr45r+XXIo9cP
        R5QUVTVXjJ6oojkZ9YI8QqlObvU7wy7bjcCwXPNZOOftz2nwWgsbvsCUJCWH+jdx
        sxPnHKzhm+/b5DtFUkWWqcFTzjTIUu61ru2P3mBw4qVUq7ZtDpelQDRrK9O8Zutm
        NHz6a4uPVymZ+DAXXbpyb/uBxa3Shlg9F8fnCbvxK/eG3MHacV3URuPMrSXBiLxg
        Z3Vms/EY96Jc5lP/Ooi2R6X/ExjqmAl3P51T+c8B5fWmcBcUr2Ok/5mzk53cU6cG
        /kiFHaFpriV1uxPMUgP17VGhi9sVAgMBAAGjggEIMIIBBDAOBgNVHQ8BAf8EBAMC
        AYYwHQYDVR0lBBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMBMBIGA1UdEwEB/wQIMAYB
        Af8CAQAwHQYDVR0OBBYEFBQusxe3WFbLrlAJQOYfr52LFMLGMB8GA1UdIwQYMBaA
        FHm0WeZ7tuXkAXOACIjIGlj26ZtuMDIGCCsGAQUFBwEBBCYwJDAiBggrBgEFBQcw
        AoYWaHR0cDovL3gxLmkubGVuY3Iub3JnLzAnBgNVHR8EIDAeMBygGqAYhhZodHRw
        Oi8veDEuYy5sZW5jci5vcmcvMCIGA1UdIAQbMBkwCAYGZ4EMAQIBMA0GCysGAQQB
        gt8TAQEBMA0GCSqGSIb3DQEBCwUAA4ICAQCFyk5HPqP3hUSFvNVneLKYY611TR6W
        PTNlclQtgaDqw+34IL9fzLdwALduO/ZelN7kIJ+m74uyA+eitRY8kc607TkC53wl
        ikfmZW4/RvTZ8M6UK+5UzhK8jCdLuMGYL6KvzXGRSgi3yLgjewQtCPkIVz6D2QQz
        CkcheAmCJ8MqyJu5zlzyZMjAvnnAT45tRAxekrsu94sQ4egdRCnbWSDtY7kh+BIm
        lJNXoB1lBMEKIq4QDUOXoRgffuDghje1WrG9ML+Hbisq/yFOGwXD9RiX8F6sw6W4
        avAuvDszue5L3sz85K+EC4Y/wFVDNvZo4TYXao6Z0f+lQKc0t8DQYzk1OXVu8rp2
        yJMC6alLbBfODALZvYH7n7do1AZls4I9d1P4jnkDrQoxB3UqQ9hVl3LEKQ73xF1O
        yK5GhDDX8oVfGKF5u+decIsH4YaTw7mP3GFxJSqv3+0lUFJoi5Lc5da149p90Ids
        hCExroL1+7mryIkXPeFM5TgO9r0rvZaBFOvV2z0gp35Z0+L4WPlbuEjN/lxPFin+
        HlUjr8gRsI3qfJOQFy/9rKIJR0Y/8Omwt/8oTWgy1mdeHmmjk7j1nYsvC9JSQ6Zv
        MldlTTKB3zhThV1+XWYp6rjd5JW1zbVWEkLNxE7GJThEUG3szgBVGP7pSWTUTsqX
        nLRbwHOoq7hHwg==
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
