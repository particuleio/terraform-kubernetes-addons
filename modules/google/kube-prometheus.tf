locals {
  kube-prometheus-stack = merge(
    local.helm_defaults,
    {
      name                                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "kube-prometheus-stack")].name
      chart                                 = local.helm_dependencies[index(local.helm_dependencies.*.name, "kube-prometheus-stack")].name
      repository                            = local.helm_dependencies[index(local.helm_dependencies.*.name, "kube-prometheus-stack")].repository
      chart_version                         = local.helm_dependencies[index(local.helm_dependencies.*.name, "kube-prometheus-stack")].version
      namespace                             = "monitoring"
      grafana_service_account_name          = "kube-prometheus-stack-grafana"
      prometheus_service_account_name       = "kube-prometheus-stack-prometheus"
      workload_identity_use_existing_k8s_sa = false
      grafana_create_iam_resources          = false
      grafana_iam_policy_override           = null
      thanos_create_iam_resources           = true
      thanos_iam_policy_override            = null
      thanos_sidecar_enabled                = false
      thanos_create_bucket                  = true
      thanos_bucket                         = "thanos-store-${var.cluster-name}"
      thanos_bucket_force_destroy           = false
      thanos_bucket_location                = ""
      thanos_kms_bucket_location            = ""
      thanos_store_config                   = null
      thanos_version                        = "v0.30.0"
      thanos_service_account                = ""
      enabled                               = false
      allowed_cidrs                         = ["0.0.0.0/0"]
      default_network_policy                = true
      default_global_requests               = false
      default_global_limits                 = false
      manage_crds                           = true
      cloud_storage_service_account         = ""
      name_prefix                           = "kube-prometheus-stack"
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
    pspEnabled: false
  serviceAccount:
    create: true
    name: ${local.kube-prometheus-stack["grafana_service_account_name"]}
    nameTest: ${local.kube-prometheus-stack["grafana_service_account_name"]}-test
    annotations:
      iam.gke.io/gcp-service-account: ${local.kube-prometheus-stack["enabled"] ? module.iam_assumable_sa_kube-prometheus-stack_grafana[0].gcp_service_account_email : ""}
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
  serviceAccount:
    create: true
    name: ${local.kube-prometheus-stack["name_prefix"]}-thanos
    annotations:
      iam.gke.io/gcp-service-account: ${local.kube-prometheus-stack["thanos_sidecar_enabled"] ? module.iam_assumable_sa_kube-prometheus-stack_thanos[0].gcp_service_account_email : ""}
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

  values_dashboard_ingress-nginx = <<VALUES
grafana:
  dashboards:
    default:
      nginx-ingress:
        url: https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/grafana/dashboards/nginx.json
VALUES
  values_dashboard_cert-manager  = <<VALUES
grafana:
  dashboards:
    default:
      cert-manager:
        gnetId: 11001
        revision: 1
        datasource: ${local.kube-prometheus-stack.enabled ? "Prometheus" : local.victoria-metrics-k8s-stack.enabled ? "VictoriaMetrics" : ""}
VALUES

  values_dashboard_node_exporter = <<VALUES
grafana:
  dashboards:
    default:
      node-exporter-full:
        gnetId: 1860
        revision: 21
        datasource: ${local.kube-prometheus-stack.enabled ? "Prometheus" : local.victoria-metrics-k8s-stack.enabled ? "VictoriaMetrics" : ""}
      node-exporter:
        gnetId: 11074
        revision: 9
        datasource: ${local.kube-prometheus-stack.enabled ? "Prometheus" : local.victoria-metrics-k8s-stack.enabled ? "VictoriaMetrics" : ""}
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
type: GCS
config:
  bucket: ${local.kube-prometheus-stack["thanos_bucket"]}
VALUES

  thanos_store_config_computed = local.kube-prometheus-stack["thanos_store_config"] == null ? local.thanos_store_config_default : local.kube-prometheus-stack["thanos_store_config"]

}

module "iam_assumable_sa_kube-prometheus-stack_grafana" {
  count               = local.kube-prometheus-stack["enabled"] ? 1 : 0
  source              = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version             = "~> 27.0"
  namespace           = local.kube-prometheus-stack["namespace"]
  project_id          = var.project_id
  name                = local.kube-prometheus-stack["grafana_service_account_name"]
  use_existing_k8s_sa = local.kube-prometheus-stack["workload_identity_use_existing_k8s_sa"]
}

module "iam_assumable_sa_kube-prometheus-stack_thanos" {
  count               = local.kube-prometheus-stack["enabled"] && local.kube-prometheus-stack["thanos_sidecar_enabled"] ? 1 : 0
  source              = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version             = "~> 27.0"
  namespace           = local.kube-prometheus-stack["namespace"]
  project_id          = var.project_id
  name                = "${local.kube-prometheus-stack["name_prefix"]}-thanos"
  use_existing_k8s_sa = local.kube-prometheus-stack["workload_identity_use_existing_k8s_sa"]
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

module "kube-prometheus-stack_thanos_bucket_iam" {
  count   = local.kube-prometheus-stack["enabled"] && local.kube-prometheus-stack["thanos_create_bucket"] ? 1 : 0
  source  = "terraform-google-modules/iam/google//modules/storage_buckets_iam"
  version = "~> 7.6"

  mode            = "additive"
  storage_buckets = [module.kube-prometheus-stack_kube-prometheus-stack_bucket[0].name]
  bindings = {
    "roles/storage.objectViewer" = [
      "serviceAccount:${module.iam_assumable_sa_kube-prometheus-stack_thanos[0].gcp_service_account_email}"
    ]
    "roles/storage.objectAdmin" = [
      "serviceAccount:${module.iam_assumable_sa_kube-prometheus-stack_thanos[0].gcp_service_account_email}"
    ]
  }
}

module "kube-prometheus-stack_grafana-iam-member" {
  count   = local.kube-prometheus-stack["enabled"] ? 1 : 0
  source  = "terraform-google-modules/iam/google//modules/member_iam"
  version = "~> 7.6"

  service_account_address = module.iam_assumable_sa_kube-prometheus-stack_grafana[0].gcp_service_account_email
  project_id              = var.project_id
  project_roles = [
    "roles/monitoring.viewer",
    "roles/logging.viewer",
    "roles/compute.viewer"
  ]
}

module "kube-prometheus-stack_thanos_kms_bucket" {
  count   = local.kube-prometheus-stack["enabled"] && local.kube-prometheus-stack["thanos_create_bucket"] ? 1 : 0
  source  = "terraform-google-modules/kms/google"
  version = "2.2.2"

  project_id = var.project_id
  location   = local.kube-prometheus-stack["thanos_kms_bucket_location"]
  keyring    = "thanos"
  keys       = ["thanos"]
  owners = [
    "serviceAccount:${local.kube-prometheus-stack["cloud_storage_service_account"]}"
  ]
  set_owners_for = [
    "thanos"
  ]
}

module "kube-prometheus-stack_kube-prometheus-stack_bucket" {
  count = local.kube-prometheus-stack["enabled"] && local.kube-prometheus-stack["thanos_create_bucket"] ? 1 : 0

  source     = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version    = "~> 4.0"
  project_id = var.project_id
  location   = local.kube-prometheus-stack["thanos_bucket_location"]

  name = local.kube-prometheus-stack["thanos_bucket"]

  encryption = {
    default_kms_key_name = module.kube-prometheus-stack_thanos_kms_bucket[0].keys.thanos
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

resource "random_string" "grafana_password" {
  count   = local.kube-prometheus-stack["enabled"] || local.victoria-metrics-k8s-stack["enabled"] ? 1 : 0
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

output "kube-prometheus-stack" {
  value = {
    iam_assumable_sa_kube-prometheus-stack_grafana = module.iam_assumable_sa_kube-prometheus-stack_grafana[*]
    iam_assumable_sa_kube-prometheus-stack_thanos  = module.iam_assumable_sa_kube-prometheus-stack_thanos[*]
  }
}

output "kube-prometheus-stack_sensitive" {
  value = {
    grafana_password = element(concat(random_string.grafana_password.*.result, [""]), 0)
  }
  sensitive = true
}
