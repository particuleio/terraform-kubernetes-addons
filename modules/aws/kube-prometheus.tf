locals {
  kube-prometheus-stack = merge(
    local.helm_defaults,
    {
      name                                 = "kube-prometheus-stack"
      namespace                            = "monitoring"
      chart                                = "kube-prometheus-stack"
      repository                           = "https://prometheus-community.github.io/helm-charts"
      grafana_service_account_name         = "kube-prometheus-stack-grafana"
      cloudwatch_create_iam_resources_irsa = false
      cloudwatch_iam_policy_override       = null
      enabled                              = false
      chart_version                        = "12.9.2"
      allowed_cidrs                        = ["0.0.0.0/0"]
      default_network_policy               = true
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
  serviceAccount:
    create: true
    name: ${local.kube-prometheus-stack["grafana_service_account_name"]}
    nameTest: ${local.kube-prometheus-stack["grafana_service_account_name"]}-test
    annotations:
      eks.amazonaws.com/role-arn: "${local.kube-prometheus-stack["enabled"] && local.kube-prometheus-stack["cloudwatch_create_iam_resources_irsa"] ? module.iam_assumable_role_kube-prometheus-stack.this_iam_role_arn : ""}"
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
}

module "iam_assumable_role_kube-prometheus-stack" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> 3.0"
  create_role                   = local.kube-prometheus-stack["enabled"] && local.kube-prometheus-stack["cloudwatch_create_iam_resources_irsa"]
  role_name                     = "tf-${var.cluster-name}-${local.kube-prometheus-stack["name"]}-irsa"
  provider_url                  = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns              = local.kube-prometheus-stack["enabled"] && local.kube-prometheus-stack["cloudwatch_create_iam_resources_irsa"] ? [aws_iam_policy.kube-prometheus-stack[0].arn] : []
  number_of_role_policy_arns    = 1
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.kube-prometheus-stack["namespace"]}:${local.kube-prometheus-stack["grafana_service_account_name"]}"]
  tags                          = local.tags
}

resource "aws_iam_policy" "kube-prometheus-stack" {
  count  = local.kube-prometheus-stack["enabled"] && local.kube-prometheus-stack["cloudwatch_create_iam_resources_irsa"] ? 1 : 0
  name   = "tf-${var.cluster-name}-${local.kube-prometheus-stack["name"]}"
  policy = local.kube-prometheus-stack["cloudwatch_iam_policy_override"] == null ? data.aws_iam_policy_document.kube-prometheus-stack.json : local.kube-prometheus-stack["cloudwatch_iam_policy_override"]
}

data "aws_iam_policy_document" "kube-prometheus-stack" {
  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:DescribeAlarmsForMetric",
      "cloudwatch:DescribeAlarmHistory",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:GetMetricData"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:DescribeLogGroups",
      "logs:GetLogGroupFields",
      "logs:StartQuery",
      "logs:StopQuery",
      "logs:GetQueryResults",
      "logs:GetLogEvents"
    ]

    resources = ["*"]

  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions"
    ]

    resources = ["*"]
  }
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions"
    ]

    resources = ["*"]

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
    local.cluster-autoscaler["enabled"] ? local.values_dashboard_cluster-autoscaler : null,
    local.ingress-nginx["enabled"] ? local.values_dashboard_ingress-nginx : null
  ])
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
