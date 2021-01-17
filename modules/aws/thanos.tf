locals {
  thanos = merge(
    local.helm_defaults,
    {
      name                      = "thanos"
      namespace                 = "monitoring"
      chart                     = "thanos"
      repository                = "https://charts.bitnami.com/bitnami"
      create_iam_resources_irsa = true
      iam_policy_override       = null
      create_ns                 = false
      version                   = "v0.17.2"
      enabled                   = false
      chart_version             = "3.3.0"
      allowed_cidrs             = ["0.0.0.0/0"]
      default_network_policy    = true
      default_global_requests   = false
      default_global_limits     = false
      create_bucket             = false
      bucket                    = "thanos-store-${var.cluster-name}"
      bucket_force_destroy      = false
      generate_ca               = false
      trusted_ca_content        = null
    },
    var.thanos
  )

  thanos-tls-querier = { for k, v in var.thanos-tls-querier : k => merge(
    local.helm_defaults,
    {
      name                    = "${local.thanos["name"]}-tls-querier-${k}"
      chart                   = local.thanos["chart"]
      repository              = local.thanos["repository"]
      version                 = local.thanos["version"]
      enabled                 = false
      chart_version           = local.thanos["chart_version"]
      generate_cert           = local.thanos["generate_ca"]
      client_server_name      = ""
      stores                  = []
      default_global_requests = false
      default_global_limits   = false
    },
    v,
  ) }

  values_thanos = <<-VALUES
    metrics:
      enabled: true
      serviceMonitor:
        enabled: ${local.kube-prometheus-stack["enabled"] ? "true" : "false"}
    query:
      replicaLabel:
        - prometheus_replica
      enabled: true
      dnsDiscovery:
        enabled: true
        sidecarsService: prometheus-operated
        sidecarsNamespace: "${local.kube-prometheus-stack["namespace"]}"
      autoscaling:
        enabled: true
        minReplicas: 2
        maxReplicas: 4
        targetCPU: 70
        targetMemory: 70
      pdb:
        create: true
        minAvailable: 1
      stores: ${jsonencode([for k, v in local.thanos-tls-querier : "dnssrv+_grpc._tcp.${v["name"]}-query.${local.thanos["namespace"]}.svc.cluster.local"])}
    queryFrontend:
      enabled: true
      autoscaling:
        enabled: true
        minReplicas: 2
        maxReplicas: 4
        targetCPU: 70
        targetMemory: 70
      pdb:
        create: true
        minAvailable: 1
    compactor:
      strategyType: Recreate
      enabled: true
      serviceAccount:
        annotations:
          eks.amazonaws.com/role-arn: "${local.thanos["enabled"] && local.thanos["create_iam_resources_irsa"] ? module.iam_assumable_role_thanos.this_iam_role_arn : ""}"
    storegateway:
      enabled: true
      serviceAccount:
        annotations:
          eks.amazonaws.com/role-arn: "${local.thanos["enabled"] && local.thanos["create_iam_resources_irsa"] ? module.iam_assumable_role_thanos.this_iam_role_arn : ""}"
      autoscaling:
        enabled: true
        minReplicas: 2
        maxReplicas: 4
        targetCPU: 70
        targetMemory: 70
      pdb:
        create: true
        minAvailable: 1
    VALUES

  values_thanos-tls-querier = { for k, v in local.thanos-tls-querier : k => merge(
    {
      values = <<-VALUES
        metrics:
          enabled: true
          serviceMonitor:
            enabled: ${local.kube-prometheus-stack["enabled"] ? "true" : "false"}
        query:
          enabled: true
          dnsDiscovery:
            enabled: false
          autoscaling:
            enabled: true
            minReplicas: 2
            maxReplicas: 4
            targetCPU: 50
            targetMemory: 50
          pdb:
            create: true
            minAvailable: 1
          grpcTLS:
            client:
              secure: true
              key: |
                ${indent(8, v["generate_cert"] ? tls_private_key.thanos-tls-querier-cert-key[k].private_key_pem : "")}
              cert: |
                ${indent(8, v["generate_cert"] ? tls_locally_signed_cert.thanos-tls-querier-cert[k].cert_pem : "")}
              servername: ${v["client_server_name"]}
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

  values_store_config = <<VALUES
objstoreConfig:
  type: S3
  config:
    bucket: ${local.thanos["bucket"]}
    region: ${data.aws_region.current.name}
    endpoint: s3.${data.aws_region.current.name}.amazonaws.com
    sse_config:
      type: "SSE-S3"
VALUES

  values_thanos_global_requests = <<VALUES
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

  values_thanos_global_limits = <<VALUES
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
  version                      = "~> 3.0"
  create_role                  = local.thanos["enabled"] && local.thanos["create_iam_resources_irsa"]
  role_name                    = "${var.cluster-name}-${local.thanos["name"]}-thanos-irsa"
  provider_url                 = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns             = local.thanos["enabled"] && local.thanos["create_iam_resources_irsa"] ? [aws_iam_policy.thanos[0].arn] : []
  number_of_role_policy_arns   = 1
  oidc_subjects_with_wildcards = ["system:serviceaccount:${local.thanos["namespace"]}:${local.thanos["name"]}-*"]
  tags                         = local.tags
}

resource "aws_iam_policy" "thanos" {
  count  = local.thanos["enabled"] && local.thanos["create_iam_resources_irsa"] ? 1 : 0
  name   = "${var.cluster-name}-${local.thanos["name"]}-thanos"
  policy = local.thanos["iam_policy_override"] == null ? data.aws_iam_policy_document.thanos.json : local.thanos["iam_policy_override"]
}

data "aws_iam_policy_document" "thanos" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = ["arn:aws:s3:::${local.thanos["bucket"]}"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:*Object"
    ]

    resources = ["arn:aws:s3:::${local.thanos["bucket"]}/*"]
  }
}

module "thanos_bucket" {
  create_bucket = local.thanos["enabled"] && local.thanos["create_bucket"]

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 1.0"

  force_destroy = local.thanos["bucket_force_destroy"]

  bucket = local.thanos["bucket"]
  acl    = "private"

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
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
    local.thanos["extra_values"]
  ])
  namespace = local.thanos["create_ns"] ? kubernetes_namespace.thanos.*.metadata.0.name[count.index] : local.thanos["namespace"]

  depends_on = [
    helm_release.kube-prometheus-stack
  ]
}

resource "tls_private_key" "thanos-tls-querier-ca-key" {
  count       = local.thanos["generate_ca"] ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "thanos-tls-querier-ca-cert" {
  count             = local.thanos["generate_ca"] ? 1 : 0
  key_algorithm     = "ECDSA"
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
    helm_release.kube-prometheus-stack
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
  value = element(concat(tls_self_signed_cert.thanos-tls-querier-ca-cert[*].cert_pem, list("")), 0)
}
