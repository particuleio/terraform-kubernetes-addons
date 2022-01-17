locals {

  external-dns = merge(
    local.helm_defaults,
    {
      name                 = local.helm_dependencies[index(local.helm_dependencies.*.name, "external-dns")].name
      chart                = local.helm_dependencies[index(local.helm_dependencies.*.name, "external-dns")].name
      repository           = local.helm_dependencies[index(local.helm_dependencies.*.name, "external-dns")].repository
      chart_version        = local.helm_dependencies[index(local.helm_dependencies.*.name, "external-dns")].version
      namespace            = "external-dns"
      service_account_name = "external-dns"
      enabled              = false
    },
    var.external-dns
  )

  values_external-dns = <<VALUES
provider: scaleway
scaleway:
  scwAccessKey: ${local.scaleway["scw_access_key"]}
  scwSecretKey: ${local.scaleway["scw_secret_key"]}
  scwDefaultOrganizationId: ${local.scaleway["scw_default_organization_id"]}
txtPrefix: "ext-dns-"
policy: sync
logFormat: json
txtOwnerId: ${var.cluster-name}
rbac:
  create: true
  pspEnabled: false
metrics:
  enabled: ${local.kube-prometheus-stack["enabled"] || local.victoria-metrics-k8s-stack["enabled"]}
  serviceMonitor:
    enabled: ${local.kube-prometheus-stack["enabled"] || local.victoria-metrics-k8s-stack["enabled"]}
priorityClassName: ${local.priority-class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
VALUES
}

resource "kubernetes_namespace" "external-dns" {
  count = local.external-dns["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.external-dns["namespace"]
    }

    name = local.external-dns["namespace"]
  }
}

resource "helm_release" "external-dns" {
  count                 = local.external-dns["enabled"] ? 1 : 0
  repository            = local.external-dns["repository"]
  name                  = local.external-dns["name"]
  chart                 = local.external-dns["chart"]
  version               = local.external-dns["chart_version"]
  timeout               = local.external-dns["timeout"]
  force_update          = local.external-dns["force_update"]
  recreate_pods         = local.external-dns["recreate_pods"]
  wait                  = local.external-dns["wait"]
  atomic                = local.external-dns["atomic"]
  cleanup_on_fail       = local.external-dns["cleanup_on_fail"]
  dependency_update     = local.external-dns["dependency_update"]
  disable_crd_hooks     = local.external-dns["disable_crd_hooks"]
  disable_webhooks      = local.external-dns["disable_webhooks"]
  render_subchart_notes = local.external-dns["render_subchart_notes"]
  replace               = local.external-dns["replace"]
  reset_values          = local.external-dns["reset_values"]
  reuse_values          = local.external-dns["reuse_values"]
  skip_crds             = local.external-dns["skip_crds"]
  verify                = local.external-dns["verify"]
  values = [
    local.values_external-dns,
    local.external-dns["extra_values"]
  ]
  namespace = kubernetes_namespace.external-dns.*.metadata.0.name[count.index]

  depends_on = [
    helm_release.kube-prometheus-stack
  ]
}