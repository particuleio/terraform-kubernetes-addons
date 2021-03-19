locals {
  loki-stack = merge(
    local.helm_defaults,
    {
      name                      = local.helm_dependencies[index(local.helm_dependencies.*.name, "loki-stack")].name
      chart                     = local.helm_dependencies[index(local.helm_dependencies.*.name, "loki-stack")].name
      repository                = local.helm_dependencies[index(local.helm_dependencies.*.name, "loki-stack")].repository
      chart_version             = local.helm_dependencies[index(local.helm_dependencies.*.name, "loki-stack")].version
      namespace                 = "monitoring"
      create_iam_resources_irsa = true
      iam_policy_override       = null
      create_ns                 = false
      enabled                   = false
      default_network_policy    = true
      create_bucket             = true
      bucket                    = "loki-store-${var.cluster-name}"
      bucket_lifecycle_rule     = []
      bucket_force_destroy      = false
      generate_ca               = true
      trusted_ca_content        = null
      create_promtail_cert      = true
    },
    var.loki-stack
  )

  promtail = merge(
    local.helm_defaults,
    {
      name          = local.helm_dependencies[index(local.helm_dependencies.*.name, "promtail")].name
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "promtail")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "promtail")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "promtail")].version
      namespace     = local.loki-stack["namespace"]
      create_ns     = false
      enabled       = false
      loki_address  = ""
      tls_crt       = null
      tls_key       = null
    },
    var.promtail
  )

  values_loki-stack = <<-VALUES
    loki:
      serviceMonitor:
        enabled: ${local.kube-prometheus-stack["enabled"]}
      priorityClassName: ${local.priority-class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
      serviceAccount:
        name: ${local.loki-stack["name"]}
        annotations:
          eks.amazonaws.com/role-arn: "${local.loki-stack["enabled"] && local.loki-stack["create_iam_resources_irsa"] ? module.iam_assumable_role_loki-stack.this_iam_role_arn : ""}"
      persistence:
        enabled: true
      config:
        schema_config:
          configs:
            - from: 2020-10-24
              store: boltdb-shipper
              object_store: s3
              schema: v11
              index:
                prefix: loki_index_
                period: 24h
        storage_config:
          aws:
            s3: "s3://${data.aws_region.current.name}/${local.loki-stack["bucket"]}"
          boltdb_shipper:
            shared_store: s3
        compactor:
          shared_store: s3
    promtail:
      serviceMonitor:
        enabled: ${local.kube-prometheus-stack["enabled"]}
      extraCommandlineArgs:
        - -client.external-labels=cluster=${var.cluster-name}
      priorityClassName: ${local.priority-class-ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}
    VALUES

  values_promtail = <<-VALUES
    priorityClassName: ${local.priority-class-ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}
    extraArgs:
      - -client.external-labels=cluster=${var.cluster-name}
    serviceMonitor:
      enabled: ${local.kube-prometheus-stack["enabled"]}
    defaultVolumes:
      - name: containers
        hostPath:
          path: /var/lib/docker/containers
      - name: pods
        hostPath:
          path: /var/log/pods
      - name: tls
        secret:
          secretName: ${local.promtail["name"]}-tls
    defaultVolumeMounts:
      - name: containers
        mountPath: /var/lib/docker/containers
        readOnly: true
      - name: pods
        mountPath: /var/log/pods
        readOnly: true
      - name: tls
        mountPath: /tls
        readOnly: true
    config:
      lokiAddress: ${local.promtail["loki_address"]}
      snippets:
        tls_config:
          cert_file: /tls/tls.crt
          key_file: /tls/tls.key
      file: |
        server:
          log_level: info
          http_listen_port: {{ .Values.config.serverPort }}
        client:
          url: {{ .Values.config.lokiAddress }}
          tls_config:
            {{- toYaml .Values.config.snippets.tls_config | nindent 4 }}
        positions:
          filename: /run/promtail/positions.yaml
        scrape_configs:
          {{- tpl .Values.config.snippets.scrapeConfigs $ | nindent 2 }}
          {{- tpl .Values.config.snippets.extraScrapeConfigs . | nindent 2 }}
    tolerations:
      - effect: NoSchedule
        operator: Exists
      - key: CriticalAddonsOnly
        operator: Exists
      - effect: NoExecute
        operator: Exists
    VALUES
}

module "iam_assumable_role_loki-stack" {
  source                       = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                      = "~> 3.0"
  create_role                  = local.loki-stack["enabled"] && local.loki-stack["create_iam_resources_irsa"]
  role_name                    = "${var.cluster-name}-${local.loki-stack["name"]}-loki-stack-irsa"
  provider_url                 = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns             = local.loki-stack["enabled"] && local.loki-stack["create_iam_resources_irsa"] ? [aws_iam_policy.loki-stack[0].arn] : []
  number_of_role_policy_arns   = 1
  oidc_subjects_with_wildcards = ["system:serviceaccount:${local.loki-stack["namespace"]}:${local.loki-stack["name"]}"]
  tags                         = local.tags
}

resource "aws_iam_policy" "loki-stack" {
  count  = local.loki-stack["enabled"] && local.loki-stack["create_iam_resources_irsa"] ? 1 : 0
  name   = "${var.cluster-name}-${local.loki-stack["name"]}-loki-stack"
  policy = local.loki-stack["iam_policy_override"] == null ? data.aws_iam_policy_document.loki-stack.json : local.loki-stack["iam_policy_override"]
}

data "aws_iam_policy_document" "loki-stack" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = ["arn:aws:s3:::${local.loki-stack["bucket"]}"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:*Object"
    ]

    resources = ["arn:aws:s3:::${local.loki-stack["bucket"]}/*"]
  }
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
    helm_release.kube-prometheus-stack
  ]
}
resource "helm_release" "promtail" {
  count                 = local.promtail["enabled"] ? 1 : 0
  repository            = local.promtail["repository"]
  name                  = local.promtail["name"]
  chart                 = local.promtail["chart"]
  version               = local.promtail["chart_version"]
  timeout               = local.promtail["timeout"]
  force_update          = local.promtail["force_update"]
  recreate_pods         = local.promtail["recreate_pods"]
  wait                  = local.promtail["wait"]
  atomic                = local.promtail["atomic"]
  cleanup_on_fail       = local.promtail["cleanup_on_fail"]
  dependency_update     = local.promtail["dependency_update"]
  disable_crd_hooks     = local.promtail["disable_crd_hooks"]
  disable_webhooks      = local.promtail["disable_webhooks"]
  render_subchart_notes = local.promtail["render_subchart_notes"]
  replace               = local.promtail["replace"]
  reset_values          = local.promtail["reset_values"]
  reuse_values          = local.promtail["reuse_values"]
  skip_crds             = local.promtail["skip_crds"]
  verify                = local.promtail["verify"]
  values = [
    local.values_promtail,
    local.promtail["extra_values"]
  ]
  namespace = local.promtail["namespace"]

  depends_on = [
    helm_release.kube-prometheus-stack,
    kubernetes_secret.loki-stack-ca,
    kubernetes_secret.promtail-tls
  ]
}

module "loki_bucket" {
  create_bucket = local.loki-stack["enabled"] && local.loki-stack["create_bucket"]

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 1.0"

  force_destroy = local.loki-stack["bucket_force_destroy"]

  bucket = local.loki-stack["bucket"]
  acl    = "private"

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule = local.loki-stack["bucket_lifecycle_rule"]
}

resource "tls_private_key" "loki-stack-ca-key" {
  count       = local.loki-stack["enabled"] && local.loki-stack["generate_ca"] ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "loki-stack-ca-cert" {
  count             = local.loki-stack["enabled"] && local.loki-stack["generate_ca"] ? 1 : 0
  key_algorithm     = "ECDSA"
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

resource "tls_private_key" "promtail-key" {
  count       = local.loki-stack["enabled"] && local.loki-stack["generate_ca"] && local.loki-stack["create_promtail_cert"] ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "promtail-csr" {
  count           = local.loki-stack["enabled"] && local.loki-stack["generate_ca"] && local.loki-stack["create_promtail_cert"] ? 1 : 0
  key_algorithm   = "ECDSA"
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
  ca_key_algorithm   = "ECDSA"
  ca_private_key_pem = tls_private_key.loki-stack-ca-key[count.index].private_key_pem
  ca_cert_pem        = tls_self_signed_cert.loki-stack-ca-cert[count.index].cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth"
  ]
}

resource "kubernetes_secret" "promtail-tls" {
  count = local.promtail["enabled"] ? 1 : 0
  metadata {
    name      = "${local.promtail["name"]}-tls"
    namespace = local.promtail["namespace"]
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = local.promtail["tls_crt"]
    "tls.key" = local.promtail["tls_key"]
  }
}

output "loki-stack-ca" {
  value = element(concat(tls_self_signed_cert.loki-stack-ca-cert[*].cert_pem, list("")), 0)
}

output "promtail-key" {
  value     = element(concat(tls_private_key.promtail-key[*].private_key_pem, list("")), 0)
  sensitive = true
}

output "promtail-cert" {
  value     = element(concat(tls_locally_signed_cert.promtail-cert[*].cert_pem, list("")), 0)
  sensitive = true
}
