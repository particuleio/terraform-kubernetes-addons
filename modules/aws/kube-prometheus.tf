locals {
  kube-prometheus-stack = merge(
    local.helm_defaults,
    {
      name                   = "kube-prometheus-stack"
      namespace              = "monitoring"
      chart                  = "kube-prometheus-stack"
      repository             = "https://prometheus-community.github.io/helm-charts"
      enabled                = false
      chart_version          = "11.0.2"
      allowed_cidrs          = ["0.0.0.0/0"]
      default_network_policy = true
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
  dashboards:
    default:
      kong-dash:
        gnetId: 7424
        revision: 6
        datasource: Prometheus
      nginx-ingress:
        url: https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/grafana/dashboards/nginx.json
      cluster-autoscaler:
        gnetId: 3831
        datasource: Prometheus
prometheus-node-exporter:
  priorityClassName: ${local.priority-class-ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}
prometheus:
  prometheusSpec:
    priorityClassName: ${local.priority-class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
alertmanager:
  alertmanagerSpec:
    priorityClassName: ${local.priority-class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
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
  values = [
    local.values_kube-prometheus-stack,
    local.kube-prometheus-stack["extra_values"]
  ]
  namespace = kubernetes_namespace.kube-prometheus-stack.*.metadata.0.name[count.index]
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
        port     = "8443"
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
  value     = random_string.grafana_password.*.result
  sensitive = true
}
