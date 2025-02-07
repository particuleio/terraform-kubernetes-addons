locals {

  thanos = merge(
    local.helm_defaults,
    {
      name                      = "thanos"
      chart                     = local.helm_dependencies[index(local.helm_dependencies.*.name, "oci://registry-1.docker.io/bitnamicharts/thanos")].name
      repository                = ""
      chart_version             = local.helm_dependencies[index(local.helm_dependencies.*.name, "oci://registry-1.docker.io/bitnamicharts/thanos")].version
      namespace                 = "monitoring"
      create_iam_resources_irsa = true
      iam_policy_override       = null
      create_ns                 = false
      enabled                   = false
      default_network_policy    = true
      default_global_requests   = false
      default_global_limits     = false
      create_bucket             = false
      bucket                    = "thanos-store-${var.cluster-name}"
      bucket_force_destroy      = false
      bucket_enforce_tls        = false
      generate_ca               = false
      trusted_ca_content        = null
      name_prefix               = "${var.cluster-name}-thanos"
    },
    var.thanos
  )

  values_thanos = <<-VALUES
    receive:
      enabled: false
      pdb:
        create: true
        minAvailable: 1
      serviceAccount:
        annotations:
          eks.amazonaws.com/role-arn: "${local.thanos["enabled"] && local.thanos["create_iam_resources_irsa"] ? module.iam_assumable_role_thanos.iam_role_arn : ""}"
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
      serviceAccount:
        annotations:
          eks.amazonaws.com/role-arn: "${local.thanos["enabled"] && local.thanos["create_iam_resources_irsa"] ? module.iam_assumable_role_thanos.iam_role_arn : ""}"
    storegateway:
      extraFlags:
        - --ignore-deletion-marks-delay=24h
      replicaCount: 2
      enabled: true
      serviceAccount:
        annotations:
          eks.amazonaws.com/role-arn: "${local.thanos["enabled"] && local.thanos["create_iam_resources_irsa"] ? module.iam_assumable_role_thanos.iam_role_arn : ""}"
      pdb:
        create: true
        minAvailable: 1
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
        bucket: ${local.thanos["bucket"]}
        region: ${data.aws_region.current.name}
        endpoint: s3.${data.aws_region.current.name}.amazonaws.com
        sse_config:
          type: "SSE-S3"
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

module "iam_assumable_role_thanos" {
  source                       = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                      = "~> 5.0"
  create_role                  = local.thanos["enabled"] && local.thanos["create_iam_resources_irsa"]
  role_name                    = local.thanos["name_prefix"]
  provider_url                 = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns             = local.thanos["enabled"] && local.thanos["create_iam_resources_irsa"] ? [aws_iam_policy.thanos[0].arn] : []
  number_of_role_policy_arns   = 1
  oidc_subjects_with_wildcards = ["system:serviceaccount:${local.thanos["namespace"]}:${local.thanos["name"]}-*"]
  tags                         = local.tags
}


resource "aws_iam_policy" "thanos" {
  count  = local.thanos["enabled"] && local.thanos["create_iam_resources_irsa"] ? 1 : 0
  name   = local.thanos["name_prefix"]
  policy = local.thanos["iam_policy_override"] == null ? data.aws_iam_policy_document.thanos.json : local.thanos["iam_policy_override"]
  tags   = local.tags
}


data "aws_iam_policy_document" "thanos" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = ["arn:${local.arn-partition}:s3:::${local.thanos["bucket"]}"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:*Object"
    ]

    resources = ["arn:${local.arn-partition}:s3:::${local.thanos["bucket"]}/*"]
  }
}


module "thanos_bucket" {
  create_bucket = local.thanos["enabled"] && local.thanos["create_bucket"]

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  force_destroy = local.thanos["bucket_force_destroy"]

  bucket = local.thanos["bucket"]
  acl    = "private"

  versioning = {
    status = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  logging = local.s3-logging.enabled ? {
    target_bucket = local.s3-logging.create_bucket ? module.s3_logging_bucket.s3_bucket_id : local.s3-logging.custom_bucket_id
    target_prefix = "${var.cluster-name}/${local.thanos.name}/"
  } : {}

  attach_deny_insecure_transport_policy = local.thanos["bucket_enforce_tls"]

  tags = local.tags
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
  early_renewal_hours   = 720

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
