locals {
  prometheus_operator = merge(
    local.helm_defaults,
    {
      name                   = "prometheus-operator"
      namespace              = "monitoring"
      chart                  = "prometheus-operator"
      repository             = "https://prometheus-community.github.io/helm-charts"
      kiam_allowed_regexp    = "^$"
      enabled                = false
      chart_version          = "v9.3.1"
      allowed_cidr           = "0.0.0.0/0"
      default_network_policy = true
    },
    var.prometheus_operator
  )

  values_prometheus_operator = <<VALUES
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
      - name: 'default' # Configure a dashboard provider file to
        orgId: 1        # put Kong dashboard into.
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
  priorityClassName: ${local.priority_class_ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}
prometheus:
  prometheusSpec:
    priorityClassName: ${local.priority_class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
alertmanager:
  alertmanagerSpec:
    priorityClassName: ${local.priority_class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
VALUES
}


resource "kubernetes_namespace" "prometheus_operator" {
  count = local.prometheus_operator["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.prometheus_operator["namespace"]
    }
    annotations = {
      "iam.amazonaws.com/permitted" = local.kiam["enabled"] ? local.prometheus_operator["kiam_allowed_regexp"] : "^$"
    }

    name = local.prometheus_operator["namespace"]
  }
}

resource "random_string" "grafana_password" {
  count   = local.prometheus_operator["enabled"] ? 1 : 0
  length  = 16
  special = false
}

resource "helm_release" "prometheus_operator" {
  count                 = local.prometheus_operator["enabled"] ? 1 : 0
  repository            = local.prometheus_operator["repository"]
  name                  = local.prometheus_operator["name"]
  chart                 = local.prometheus_operator["chart"]
  version               = local.prometheus_operator["chart_version"]
  timeout               = local.prometheus_operator["timeout"]
  force_update          = local.prometheus_operator["force_update"]
  recreate_pods         = local.prometheus_operator["recreate_pods"]
  wait                  = local.prometheus_operator["wait"]
  atomic                = local.prometheus_operator["atomic"]
  cleanup_on_fail       = local.prometheus_operator["cleanup_on_fail"]
  dependency_update     = local.prometheus_operator["dependency_update"]
  disable_crd_hooks     = local.prometheus_operator["disable_crd_hooks"]
  disable_webhooks      = local.prometheus_operator["disable_webhooks"]
  render_subchart_notes = local.prometheus_operator["render_subchart_notes"]
  replace               = local.prometheus_operator["replace"]
  reset_values          = local.prometheus_operator["reset_values"]
  reuse_values          = local.prometheus_operator["reuse_values"]
  skip_crds             = local.prometheus_operator["skip_crds"]
  verify                = local.prometheus_operator["verify"]
  values = [
    local.values_prometheus_operator,
    local.prometheus_operator["extra_values"]
  ]
  namespace = kubernetes_namespace.prometheus_operator.*.metadata.0.name[count.index]
}

resource "kubernetes_network_policy" "prometheus_operator_default_deny" {
  count = local.prometheus_operator["enabled"] && local.prometheus_operator["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.prometheus_operator.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.prometheus_operator.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "prometheus_operator_allow_namespace" {
  count = local.prometheus_operator["enabled"] && local.prometheus_operator["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.prometheus_operator.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.prometheus_operator.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.prometheus_operator.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "prometheus_operator_allow_ingress_nginx" {
  count = local.prometheus_operator["enabled"] && local.prometheus_operator["default_network_policy"] && local.nginx_ingress["enabled"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.prometheus_operator.*.metadata.0.name[count.index]}-allow-ingress-nginx"
    namespace = kubernetes_namespace.prometheus_operator.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "app.kubernetes.io/name"
        operator = "In"
        values   = ["grafana"]
      }
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "prometheus_operator_allow_control_plane" {
  count = local.prometheus_operator["enabled"] && local.prometheus_operator["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.prometheus_operator.*.metadata.0.name[count.index]}-allow-control-plane"
    namespace = kubernetes_namespace.prometheus_operator.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "app"
        operator = "In"
        values   = ["${local.prometheus_operator["name"]}-operator"]
      }
    }

    ingress {
      ports {
        port     = "8443"
        protocol = "TCP"
      }

      dynamic "from" {
        for_each = local.prometheus_operator["allowed_cidrs"]
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
