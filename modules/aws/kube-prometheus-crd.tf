locals {

  prometheus-operator_crd_version = (local.victoria-metrics-k8s-stack.enabled && local.victoria-metrics-k8s-stack.install_prometheus_operator_crds) || (local.kube-prometheus-stack.enabled && local.kube-prometheus-stack.manage_crds) ? yamldecode(data.http.prometheus-operator_version.0.response_body).appVersion : ""

  prometheus-operator_crds = [
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${local.prometheus-operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagerconfigs.yaml",
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${local.prometheus-operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml",
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${local.prometheus-operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml",
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${local.prometheus-operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml",
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${local.prometheus-operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml",
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${local.prometheus-operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml",
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${local.prometheus-operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml",
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${local.prometheus-operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml"
  ]

  prometheus-operator_chart = "https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-${local.kube-prometheus-stack.chart_version}/charts/kube-prometheus-stack/Chart.yaml"

  prometheus-operator_crds_apply = (local.victoria-metrics-k8s-stack.enabled && local.victoria-metrics-k8s-stack.install_prometheus_operator_crds) || (local.kube-prometheus-stack.enabled && local.kube-prometheus-stack.manage_crds) ? { for k, v in data.http.prometheus-operator_crds : lower(join("/", compact([yamldecode(v.response_body).apiVersion, yamldecode(v.response_body).kind, lookup(yamldecode(v.response_body).metadata, "namespace", ""), yamldecode(v.response_body).metadata.name]))) => v.response_body
  } : null

}

data "http" "prometheus-operator_version" {
  count = (local.victoria-metrics-k8s-stack.enabled && local.victoria-metrics-k8s-stack.install_prometheus_operator_crds) || (local.kube-prometheus-stack.enabled && local.kube-prometheus-stack.manage_crds) ? 1 : 0
  url   = local.prometheus-operator_chart
}

data "http" "prometheus-operator_crds" {
  for_each = (local.victoria-metrics-k8s-stack.enabled && local.victoria-metrics-k8s-stack.install_prometheus_operator_crds) || (local.kube-prometheus-stack.enabled && local.kube-prometheus-stack.manage_crds) ? toset(local.prometheus-operator_crds) : []
  url      = each.key
}

resource "kubectl_manifest" "prometheus-operator_crds" {
  for_each          = (local.victoria-metrics-k8s-stack.enabled && local.victoria-metrics-k8s-stack.install_prometheus_operator_crds) || (local.kube-prometheus-stack.enabled && local.kube-prometheus-stack.manage_crds) ? local.prometheus-operator_crds_apply : {}
  yaml_body         = each.value
  server_side_apply = true
  force_conflicts   = true
}
