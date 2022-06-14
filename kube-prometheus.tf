locals {

  kube-prometheus-stack = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "kube-prometheus-stack")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "kube-prometheus-stack")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "kube-prometheus-stack")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "kube-prometheus-stack")].version
      namespace              = "monitoring"
      enabled                = false
      allowed_cidrs          = ["0.0.0.0/0"]
      default_network_policy = true
      manage_crds            = true
    },
    var.kube-prometheus-stack
  )

  values_kube-prometheus-stack = <<VALUES
grafana:
  rbac:
    pspEnabled: false
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

  values_dashboard_kong = <<VALUES
grafana:
  dashboards:
    default:
      kong-dash:
        gnetId: 7424
        revision: 6
        datasource: ${local.kube-prometheus-stack.enabled ? "Prometheus" : local.victoria-metrics-k8s-stack.enabled ? "VictoriaMetrics" : ""}
VALUES

  values_dashboard_ingress-nginx = <<VALUES
grafana:
  dashboards:
    default:
      nginx-ingress:
        url: https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/grafana/dashboards/nginx.json
VALUES

  values_dashboard_cert-manager = <<VALUES
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
    local.kube-prometheus-stack["extra_values"],
    local.kong["enabled"] ? local.values_dashboard_kong : null,
    local.cert-manager["enabled"] ? local.values_dashboard_cert-manager : null,
    local.ingress-nginx["enabled"] ? local.values_dashboard_ingress-nginx : null,
    local.values_dashboard_node_exporter
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
