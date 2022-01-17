locals {
  keycloak = merge(
    local.helm_defaults,
    {
      name          = local.helm_dependencies[index(local.helm_dependencies.*.name, "keycloak")].name
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "keycloak")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "keycloak")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "keycloak")].version
      namespace     = "keycloak"
      enabled       = false
    },
    var.keycloak
  )

  values_keycloak = <<VALUES
serviceMonitor:
  enabled: ${local.kube-prometheus-stack["enabled"] || local.victoria-metrics-k8s-stack["enabled"]}
priorityClassName: ${local.priority-class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
VALUES
}

resource "kubernetes_namespace" "keycloak" {
  count = local.keycloak["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.keycloak["namespace"]
    }

    name = local.keycloak["namespace"]
  }
}

resource "helm_release" "keycloak" {
  count                 = local.keycloak["enabled"] ? 1 : 0
  repository            = local.keycloak["repository"]
  name                  = local.keycloak["name"]
  chart                 = local.keycloak["chart"]
  version               = local.keycloak["chart_version"]
  timeout               = local.keycloak["timeout"]
  force_update          = local.keycloak["force_update"]
  recreate_pods         = local.keycloak["recreate_pods"]
  wait                  = local.keycloak["wait"]
  atomic                = local.keycloak["atomic"]
  cleanup_on_fail       = local.keycloak["cleanup_on_fail"]
  dependency_update     = local.keycloak["dependency_update"]
  disable_crd_hooks     = local.keycloak["disable_crd_hooks"]
  disable_webhooks      = local.keycloak["disable_webhooks"]
  render_subchart_notes = local.keycloak["render_subchart_notes"]
  replace               = local.keycloak["replace"]
  reset_values          = local.keycloak["reset_values"]
  reuse_values          = local.keycloak["reuse_values"]
  skip_crds             = local.keycloak["skip_crds"]
  verify                = local.keycloak["verify"]
  values = [
    local.values_keycloak,
    local.keycloak["extra_values"]
  ]
  namespace = kubernetes_namespace.keycloak.*.metadata.0.name[count.index]

  depends_on = [
    helm_release.kube-prometheus-stack
  ]
}