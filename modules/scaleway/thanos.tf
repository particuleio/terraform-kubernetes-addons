locals {

  thanos = merge(
    local.helm_defaults,
    {
      name                    = local.helm_dependencies[index(local.helm_dependencies.*.name, "thanos")].name
      chart                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "thanos")].name
      repository              = local.helm_dependencies[index(local.helm_dependencies.*.name, "thanos")].repository
      chart_version           = local.helm_dependencies[index(local.helm_dependencies.*.name, "thanos")].version
      namespace               = "monitoring"
      iam_policy_override     = null
      create_ns               = false
      enabled                 = false
      default_network_policy  = true
      default_global_requests = false
      default_global_limits   = false
      create_bucket           = false
      bucket                  = "thanos-store-${var.cluster-name}"
      generate_ca             = false
      trusted_ca_content      = null
    },
    var.thanos
  )

  values_thanos = <<-VALUES
    receive:
      enabled: false
      pdb:
        create: true
        minAvailable: 1
    metrics:
      enabled: true
      serviceMonitor:
        enabled: ${local.kube-prometheus-stack["enabled"] ? "true" : "false"}
    query:
      extraFlags:
        - --query.timeout=5m
        - --query.lookback-delta=15m
        - --query.replica-label=rule_replica
      replicaCount: 2
      replicaLabel:
        - prometheus_replica
      enabled: true
      dnsDiscovery:
        enabled: true
        sidecarsService: ${local.kube-prometheus-stack["name"]}-thanos-discovery
        sidecarsNamespace: "${local.kube-prometheus-stack["namespace"]}"
      pdb:
        create: true
        minAvailable: 1
      stores: ${jsonencode(concat([for k, v in local.thanos-tls-querier : "dnssrv+_grpc._tcp.${v["name"]}-query-grpc.${local.thanos["namespace"]}.svc.cluster.local"], [for k, v in local.thanos-storegateway : "dnssrv+_grpc._tcp.${v["name"]}-storegateway.${local.thanos["namespace"]}.svc.cluster.local"]))}
    queryFrontend:
      extraFlags:
        - --query-frontend.compress-responses
        - --query-range.split-interval=12h
        - --labels.split-interval=12h
        - --query-range.max-retries-per-request=10
        - --labels.max-retries-per-request=10
        - --query-frontend.log-queries-longer-than=10s
      replicaCount: 2
      enabled: true
      pdb:
        create: true
        minAvailable: 1
    compactor:
      extraFlags:
        - --deduplication.replica-label=prometheus_replica
        - --deduplication.replica-label=rule_replica
      strategyType: Recreate
      enabled: true
    storegateway:
      extraFlags:
        - --ignore-deletion-marks-delay=24h
      replicaCount: 2
      enabled: true
      pdb:
        create: true
        minAvailable: 1
      service:
        additionalHeadless: true
    VALUES


  values_thanos_caching = <<-VALUES
    queryFrontend:
      extraFlags:
        - --query-frontend.compress-responses
        - --query-range.split-interval=12h
        - --labels.split-interval=12h
        - --query-range.max-retries-per-request=10
        - --labels.max-retries-per-request=10
        - --query-frontend.log-queries-longer-than=10s
        - |-
          --query-range.response-cache-config="config":
            "addresses":
            - "dnssrv+_memcache._tcp.${local.thanos-memcached["name"]}.${local.thanos-memcached["namespace"]}.svc.cluster.local"
            "dns_provider_update_interval": "10s"
            "max_async_buffer_size": 10000
            "max_async_concurrency": 20
            "max_get_multi_batch_size": 0
            "max_get_multi_concurrency": 100
            "max_idle_connections": 100
            "timeout": "500ms"
          "type": "memcached"
        - |-
          --labels.response-cache-config="config":
            "addresses":
            - "dnssrv+_memcache._tcp.${local.thanos-memcached["name"]}.${local.thanos-memcached["namespace"]}.svc.cluster.local"
            "dns_provider_update_interval": "10s"
            "max_async_buffer_size": 10000
            "max_async_concurrency": 20
            "max_get_multi_batch_size": 0
            "max_get_multi_concurrency": 100
            "max_idle_connections": 100
            "timeout": "500ms"
          "type": "memcached"
    storegateway:
      extraFlags:
        - --ignore-deletion-marks-delay=24h
        - |-
          --index-cache.config="config":
            "addresses":
            - "dnssrv+_memcache._tcp.${local.thanos-memcached["name"]}.${local.thanos-memcached["namespace"]}.svc.cluster.local"
            "dns_provider_update_interval": "10s"
            "max_async_buffer_size": 10000
            "max_async_concurrency": 20
            "max_get_multi_batch_size": 0
            "max_get_multi_concurrency": 100
            "max_idle_connections": 100
            "max_item_size": "1MiB"
            "timeout": "500ms"
          "type": "memcached"
        - |-
          --store.caching-bucket.config="blocks_iter_ttl": "5m"
          "chunk_object_attrs_ttl": "24h"
          "chunk_subrange_size": 16000
          "chunk_subrange_ttl": "24h"
          "config":
            "addresses":
            - "dnssrv+_memcache._tcp.${local.thanos-memcached["name"]}.${local.thanos-memcached["namespace"]}.svc.cluster.local"
            "dns_provider_update_interval": "10s"
            "max_async_buffer_size": 10000
            "max_async_concurrency": 20
            "max_get_multi_batch_size": 0
            "max_get_multi_concurrency": 100
            "max_idle_connections": 100
            "max_item_size": "1MiB"
            "timeout": "500ms"
          "max_chunks_get_range_requests": 3
          "metafile_content_ttl": "24h"
          "metafile_doesnt_exist_ttl": "15m"
          "metafile_exists_ttl": "2h"
          "metafile_max_size": "1MiB"
          "type": "memcached"
    VALUES


  values_store_config = <<-VALUES
    objstoreConfig:
      type: S3
      config:
        bucket: ${local.kube-prometheus-stack["thanos_bucket"]}
        region: ${local.kube-prometheus-stack["thanos_bucket_region"]}
        endpoint: s3.${local.kube-prometheus-stack["thanos_bucket_region"]}.scw.cloud
        access_key: ${local.scaleway["scw_access_key"]}
        secret_key: ${local.scaleway["scw_secret_key"]}
        signature_version2: false
    VALUES

  values_thanos_global_requests = <<-VALUES
    query:
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
    queryFrontend:
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
    compactor:
      resources:
        requests:
          cpu: 50m
          memory: 258Mi
    storegateway:
      resources:
        requests:
          cpu: 25m
          memory: 64Mi
    VALUES

  values_thanos_global_limits = <<-VALUES
    query:
      resources:
        limits:
          memory: 128Mi
    queryFrontend:
      resources:
        limits:
          memory: 64Mi
    compactor:
      resources:
        limits:
          memory: 2Gi
    storegateway:
      resources:
        limits:
          memory: 1Gi
    VALUES
}

resource "scaleway_object_bucket" "thanos_bucket" {
  count = local.thanos["enabled"] && local.thanos["create_bucket"] ? 1 : 0
  name  = local.thanos["bucket"]
}

resource "scaleway_object_bucket_acl" "thanos_bucket_acl" {
  count  = local.thanos["enabled"] && local.thanos["create_bucket"] ? 1 : 0
  bucket = scaleway_object_bucket.thanos_bucket.0.id
  acl    = "private"
}

resource "kubernetes_namespace" "thanos" {
  count = local.thanos["enabled"] && local.thanos["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name                               = local.thanos["namespace"]
      "${local.labels_prefix}/component" = "monitoring"
    }

    name = local.thanos["namespace"]
  }
}

resource "helm_release" "thanos" {
  count                 = local.thanos["enabled"] ? 1 : 0
  repository            = local.thanos["repository"]
  name                  = local.thanos["name"]
  chart                 = local.thanos["chart"]
  version               = local.thanos["chart_version"]
  timeout               = local.thanos["timeout"]
  force_update          = local.thanos["force_update"]
  recreate_pods         = local.thanos["recreate_pods"]
  wait                  = local.thanos["wait"]
  atomic                = local.thanos["atomic"]
  cleanup_on_fail       = local.thanos["cleanup_on_fail"]
  dependency_update     = local.thanos["dependency_update"]
  disable_crd_hooks     = local.thanos["disable_crd_hooks"]
  disable_webhooks      = local.thanos["disable_webhooks"]
  render_subchart_notes = local.thanos["render_subchart_notes"]
  replace               = local.thanos["replace"]
  reset_values          = local.thanos["reset_values"]
  reuse_values          = local.thanos["reuse_values"]
  skip_crds             = local.thanos["skip_crds"]
  verify                = local.thanos["verify"]
  values = compact([
    local.values_thanos,
    local.values_store_config,
    local.thanos["default_global_requests"] ? local.values_thanos_global_requests : null,
    local.thanos["default_global_limits"] ? local.values_thanos_global_limits : null,
    local.thanos-memcached["enabled"] ? local.values_thanos_caching : null,
    local.thanos["extra_values"]
  ])
  namespace = local.thanos["create_ns"] ? kubernetes_namespace.thanos.*.metadata.0.name[count.index] : local.thanos["namespace"]

  depends_on = [
    helm_release.kube-prometheus-stack,
    helm_release.thanos-memcached
  ]
}

resource "tls_private_key" "thanos-tls-querier-ca-key" {
  count       = local.thanos["generate_ca"] ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "thanos-tls-querier-ca-cert" {
  count             = local.thanos["generate_ca"] ? 1 : 0
  private_key_pem   = tls_private_key.thanos-tls-querier-ca-key[0].private_key_pem
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

resource "kubernetes_secret" "thanos-ca" {
  count = local.thanos["enabled"] && (local.thanos["generate_ca"] || local.thanos["trusted_ca_content"] != null) ? 1 : 0
  metadata {
    name      = "${local.thanos["name"]}-ca"
    namespace = local.thanos["create_ns"] ? kubernetes_namespace.thanos.*.metadata.0.name[count.index] : local.thanos["namespace"]
  }

  data = {
    "ca.crt" = local.thanos["generate_ca"] ? tls_self_signed_cert.thanos-tls-querier-ca-cert[count.index].cert_pem : local.thanos["trusted_ca_content"]
  }
}

output "thanos_ca" {
  value = element(concat(tls_self_signed_cert.thanos-tls-querier-ca-cert[*].cert_pem, [""]), 0)
}
