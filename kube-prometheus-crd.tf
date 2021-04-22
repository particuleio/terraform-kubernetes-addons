locals {

  prometheus-operator_crd_version = local.kube-prometheus-stack.enabled && local.kube-prometheus-stack.manage_crds ? yamldecode(data.http.prometheus-operator_version.0.body).appVersion : ""

  prometheus-operator_crds = [
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v${local.prometheus-operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagerconfigs.yaml",
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v${local.prometheus-operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml",
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v${local.prometheus-operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml",
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v${local.prometheus-operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml",
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v${local.prometheus-operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml",
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v${local.prometheus-operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml",
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v${local.prometheus-operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml",
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v${local.prometheus-operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml"
  ]

  prometheus-operator_chart = "https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-${local.kube-prometheus-stack.chart_version}/charts/kube-prometheus-stack/Chart.yaml"

}

data "http" "prometheus-operator_version" {
  count = local.kube-prometheus-stack.enabled && local.kube-prometheus-stack.manage_crds ? 1 : 0
  url   = local.prometheus-operator_chart
}

data "http" "prometheus-operator_crds" {
  for_each = local.kube-prometheus-stack.enabled && local.kube-prometheus-stack.manage_crds ? toset(local.prometheus-operator_crds) : []
  url      = each.key
}

resource "kubectl_manifest" "prometheus-operator_crds" {
  for_each  = local.kube-prometheus-stack.enabled && local.kube-prometheus-stack.manage_crds ? data.http.prometheus-operator_crds : []
  yaml_body = each.value.body
}
