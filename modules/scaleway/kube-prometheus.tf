locals {
  kube-prometheus-stack = merge(
    local.helm_defaults,
    {
      name                    = local.helm_dependencies[index(local.helm_dependencies.*.name, "kube-prometheus-stack")].name
      chart                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "kube-prometheus-stack")].name
      repository              = local.helm_dependencies[index(local.helm_dependencies.*.name, "kube-prometheus-stack")].repository
      chart_version           = local.helm_dependencies[index(local.helm_dependencies.*.name, "kube-prometheus-stack")].version
      namespace               = "monitoring"
      thanos_sidecar_enabled  = false
      thanos_create_bucket    = true
      thanos_bucket           = "thanos-store-${var.cluster-name}"
      thanos_bucket_region    = local.scaleway["region"]
      thanos_store_config     = null
      thanos_version          = "v0.25.2"
      enabled                 = false
      allowed_cidrs           = ["0.0.0.0/0"]
      default_network_policy  = true
      default_global_requests = false
      default_global_limits   = false
      manage_crds             = true
    },
    var.kube-prometheus-stack
  )

  values_kube-prometheus-stack = <<VALUES
kubeScheduler:
  enabled: false
kubeControllerManager:
  enabled: false
kubeEtcd:
  enabled: false
grafana:
  sidecar:
    dashboards:
      multicluster:
        global:
          enabled: ${local.kube-prometheus-stack["thanos_sidecar_enabled"] ? "true" : "false"}
  rbac:
    pspUseAppArmor: false
  adminPassword: ${join(",", random_string.grafana_password.*.result)}
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards/default
prometheus-node-exporter:
  priorityClassName: ${local.priority-class-ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}
prometheus:
  thanosService:
    enabled: ${local.thanos["enabled"]}
  prometheusSpec:
    priorityClassName: ${local.priority-class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
alertmanager:
  alertmanagerSpec:
    priorityClassName: ${local.priority-class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
prometheusOperator:
  admissionWebhooks:
    patch:
      podAnnotations:
        linkerd.io/inject: disabled
VALUES

  values_kps_global_requests = <<VALUES
grafana:
  resources:
    requests:
      cpu: 100m
      memory: 200Mi
prometheus:
  prometheusSpec:
    resources:
      requests:
        cpu: 50m
        memory: 1300Mi
alertmanager:
  alertmanagerSpec:
    resources:
      requests:
        cpu: 10m
        memory: 20Mi
prometheusOperator:
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
prometheus-node-exporter:
  resources:
    requests:
      cpu: 10m
      memory: 20Mi
kube-state-metrics:
  resources:
    requests:
      cpu: 10m
      memory: 50Mi
VALUES

  values_kps_global_limits = <<VALUES
grafana:
  resources:
    limits:
      cpu: 500m
      memory: 500Mi
alertmanager:
  alertmanagerSpec:
    resources:
      limits:
        cpu: 100m
        memory: 200Mi
prometheusOperator:
  resources:
    limits:
      cpu: 200m
      memory: 256Mi
prometheus-node-exporter:
  resources:
    limits:
      cpu: 100m
      memory: 200Mi
kube-state-metrics:
  resources:
    limits:
      cpu: 100m
      memory: 200Mi
VALUES

  values_dashboard_kong = <<VALUES
grafana:
  dashboards:
    default:
      kong-dash:
        gnetId: 7424
        revision: 6
        datasource: Prometheus
VALUES

  values_dashboard_ingress-nginx = <<VALUES
grafana:
  dashboards:
    default:
      nginx-ingress:
        url: https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/grafana/dashboards/nginx.json
VALUES

  values_dashboard_cluster-autoscaler = <<VALUES
grafana:
  dashboards:
    default:
      cluster-autoscaler:
        gnetId: 3831
        revision: 1
        datasource: Prometheus
VALUES

  values_dashboard_cert-manager = <<VALUES
grafana:
  dashboards:
    default:
      cert-manager:
        gnetId: 11001
        revision: 1
        datasource: Prometheus
VALUES

  values_dashboard_node_exporter = <<VALUES
grafana:
  dashboards:
    default:
      node-exporter-full:
        gnetId: 1860
        revision: 21
        datasource: Prometheus
      node-exporter:
        gnetId: 11074
        revision: 9
        datasource: Prometheus
VALUES

  values_thanos_sidecar = <<VALUES
prometheus:
  prometheusSpec:
    externalLabels:
      cluster: ${var.cluster-name}
    thanos:
      version: "${local.kube-prometheus-stack["thanos_version"]}"
      objectStorageConfig:
        key: thanos.yaml
        name: "${local.kube-prometheus-stack["thanos_bucket"]}-config"
VALUES

  values_grafana_ds = <<VALUES
grafana:
  sidecar:
    datasources:
      defaultDatasourceEnabled: false
  additionalDataSources:
  - name: Prometheus
    access: proxy
    editable: false
    orgId: 1
    type: prometheus
    url: http://${local.thanos["enabled"] ? "${local.thanos["name"]}-query-frontend:9090" : "${local.kube-prometheus-stack["name"]}-prometheus:9090"}
    version: 1
    isDefault: true
VALUES

  values_dashboard_thanos = <<VALUES
grafana:
  dashboards:
    default:
      thanos-overview:
        url: https://raw.githubusercontent.com/thanos-io/thanos/master/examples/dashboards/overview.json
      thanos-compact:
        url: https://raw.githubusercontent.com/thanos-io/thanos/master/examples/dashboards/compact.json
      thanos-query:
        url: https://raw.githubusercontent.com/thanos-io/thanos/master/examples/dashboards/query.json
      thanos-store:
        url: https://raw.githubusercontent.com/thanos-io/thanos/master/examples/dashboards/store.json
      thanos-receiver:
        url: https://raw.githubusercontent.com/thanos-io/thanos/master/examples/dashboards/receive.json
      thanos-sidecar:
        url: https://raw.githubusercontent.com/thanos-io/thanos/master/examples/dashboards/sidecar.json
      thanos-rule:
        url: https://raw.githubusercontent.com/thanos-io/thanos/master/examples/dashboards/rule.json
      thanos-replicate:
        url: https://raw.githubusercontent.com/thanos-io/thanos/master/examples/dashboards/bucket-replicate.json
VALUES

  thanos_store_config_default = <<VALUES
type: S3
config:
  bucket: ${local.kube-prometheus-stack["thanos_bucket"]}
  region: ${local.kube-prometheus-stack["thanos_bucket_region"]}
  endpoint: s3.${local.kube-prometheus-stack["thanos_bucket_region"]}.scw.cloud
  access_key: ${local.scaleway["scw_access_key"]}
  secret_key: ${local.scaleway["scw_secret_key"]}
  signature_version2: false
VALUES

  thanos_store_config_computed = local.kube-prometheus-stack["thanos_store_config"] == null ? local.thanos_store_config_default : local.kube-prometheus-stack["thanos_store_config"]

}

resource "kubernetes_secret" "kube-prometheus-stack_thanos" {
  count = local.kube-prometheus-stack["enabled"] && local.kube-prometheus-stack["thanos_sidecar_enabled"] ? 1 : 0
  metadata {
    name      = "${local.kube-prometheus-stack["thanos_bucket"]}-config"
    namespace = kubernetes_namespace.kube-prometheus-stack.*.metadata.0.name[count.index]
  }

  data = {
    "thanos.yaml" = local.thanos_store_config_computed
  }
}

resource "kubernetes_namespace" "kube-prometheus-stack" {
  count = local.kube-prometheus-stack["enabled"] ? 1 : 0

  metadata {
    labels = {
      name                               = local.kube-prometheus-stack["namespace"]
      "${local.labels_prefix}/component" = "monitoring"
    }

    name = local.kube-prometheus-stack["namespace"]
  }
}

resource "scaleway_object_bucket" "kube-prometheus-stack_thanos_bucket" {
  count = local.kube-prometheus-stack["enabled"] && local.kube-prometheus-stack["thanos_sidecar_enabled"] && local.kube-prometheus-stack["thanos_create_bucket"] ? 1 : 0
  name  = local.kube-prometheus-stack["thanos_bucket"]
  acl   = "private"
}

resource "random_string" "grafana_password" {
  count   = local.kube-prometheus-stack["enabled"] ? 1 : 0
  length  = 16
  special = false
}

resource "helm_release" "kube-prometheus-stack" {
  count                 = local.kube-prometheus-stack["enabled"] ? 1 : 0
  repository            = local.kube-prometheus-stack["repository"]
  name                  = local.kube-prometheus-stack["name"]
  chart                 = local.kube-prometheus-stack["chart"]
  version               = local.kube-prometheus-stack["chart_version"]
  timeout               = local.kube-prometheus-stack["timeout"]
  force_update          = local.kube-prometheus-stack["force_update"]
  recreate_pods         = local.kube-prometheus-stack["recreate_pods"]
  wait                  = local.kube-prometheus-stack["wait"]
  atomic                = local.kube-prometheus-stack["atomic"]
  cleanup_on_fail       = local.kube-prometheus-stack["cleanup_on_fail"]
  dependency_update     = local.kube-prometheus-stack["dependency_update"]
  disable_crd_hooks     = local.kube-prometheus-stack["disable_crd_hooks"]
  disable_webhooks      = local.kube-prometheus-stack["disable_webhooks"]
  render_subchart_notes = local.kube-prometheus-stack["render_subchart_notes"]
  replace               = local.kube-prometheus-stack["replace"]
  reset_values          = local.kube-prometheus-stack["reset_values"]
  reuse_values          = local.kube-prometheus-stack["reuse_values"]
  skip_crds             = local.kube-prometheus-stack["skip_crds"]
  verify                = local.kube-prometheus-stack["verify"]
  values = compact([
    local.values_kube-prometheus-stack,
    local.kong["enabled"] ? local.values_dashboard_kong : null,
    local.cert-manager["enabled"] ? local.values_dashboard_cert-manager : null,
    local.values_dashboard_cluster-autoscaler,
    local.ingress-nginx["enabled"] ? local.values_dashboard_ingress-nginx : null,
    local.thanos["enabled"] ? local.values_dashboard_thanos : null,
    local.values_dashboard_node_exporter,
    local.kube-prometheus-stack["thanos_sidecar_enabled"] ? local.values_thanos_sidecar : null,
    local.kube-prometheus-stack["thanos_sidecar_enabled"] ? local.values_grafana_ds : null,
    local.kube-prometheus-stack["default_global_requests"] ? local.values_kps_global_requests : null,
    local.kube-prometheus-stack["default_global_limits"] ? local.values_kps_global_limits : null,
    local.kube-prometheus-stack["extra_values"]
  ])
  namespace = kubernetes_namespace.kube-prometheus-stack.*.metadata.0.name[count.index]

  depends_on = [
    helm_release.ingress-nginx,
    kubectl_manifest.prometheus-operator_crds
  ]
}

resource "kubernetes_network_policy" "kube-prometheus-stack_default_deny" {
  count = local.kube-prometheus-stack["enabled"] && local.kube-prometheus-stack["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.kube-prometheus-stack.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.kube-prometheus-stack.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "kube-prometheus-stack_allow_namespace" {
  count = local.kube-prometheus-stack["enabled"] && local.kube-prometheus-stack["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.kube-prometheus-stack.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.kube-prometheus-stack.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.kube-prometheus-stack.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "kube-prometheus-stack_allow_ingress" {
  count = local.kube-prometheus-stack["enabled"] && local.kube-prometheus-stack["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.kube-prometheus-stack.*.metadata.0.name[count.index]}-allow-ingress"
    namespace = kubernetes_namespace.kube-prometheus-stack.*.metadata.0.name[count.index]
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

resource "kubernetes_network_policy" "kube-prometheus-stack_allow_control_plane" {
  count = local.kube-prometheus-stack["enabled"] && local.kube-prometheus-stack["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.kube-prometheus-stack.*.metadata.0.name[count.index]}-allow-control-plane"
    namespace = kubernetes_namespace.kube-prometheus-stack.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "app"
        operator = "In"
        values   = ["${local.kube-prometheus-stack["name"]}-operator"]
      }
    }

    ingress {
      ports {
        port     = "10250"
        protocol = "TCP"
      }

      dynamic "from" {
        for_each = local.kube-prometheus-stack["allowed_cidrs"]
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

output "grafana_password" {
  value     = element(concat(random_string.grafana_password.*.result, [""]), 0)
  sensitive = true
}
