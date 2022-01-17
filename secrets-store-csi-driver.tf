locals {
  secrets-store-csi-driver = merge(
    local.helm_defaults,
    {
      name          = local.helm_dependencies[index(local.helm_dependencies.*.name, "secrets-store-csi-driver")].name
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "secrets-store-csi-driver")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "secrets-store-csi-driver")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "secrets-store-csi-driver")].version
      namespace     = "kube-system"
      enabled       = false
      create_ns     = false
    },
    var.secrets-store-csi-driver
  )

  values_secrets-store-csi-driver = <<VALUES
syncSecret:
  enabled: true
enableSecretRotation: true
VALUES
}

resource "kubernetes_namespace" "secrets-store-csi-driver" {
  count = local.secrets-store-csi-driver["enabled"] && local.secrets-store-csi-driver["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name = local.secrets-store-csi-driver["namespace"]
    }

    name = local.secrets-store-csi-driver["namespace"]
  }
}

resource "helm_release" "secrets-store-csi-driver" {
  count                 = local.secrets-store-csi-driver["enabled"] ? 1 : 0
  repository            = local.secrets-store-csi-driver["repository"]
  name                  = local.secrets-store-csi-driver["name"]
  chart                 = local.secrets-store-csi-driver["chart"]
  version               = local.secrets-store-csi-driver["chart_version"]
  timeout               = local.secrets-store-csi-driver["timeout"]
  force_update          = local.secrets-store-csi-driver["force_update"]
  recreate_pods         = local.secrets-store-csi-driver["recreate_pods"]
  wait                  = local.secrets-store-csi-driver["wait"]
  atomic                = local.secrets-store-csi-driver["atomic"]
  cleanup_on_fail       = local.secrets-store-csi-driver["cleanup_on_fail"]
  dependency_update     = local.secrets-store-csi-driver["dependency_update"]
  disable_crd_hooks     = local.secrets-store-csi-driver["disable_crd_hooks"]
  disable_webhooks      = local.secrets-store-csi-driver["disable_webhooks"]
  render_subchart_notes = local.secrets-store-csi-driver["render_subchart_notes"]
  replace               = local.secrets-store-csi-driver["replace"]
  reset_values          = local.secrets-store-csi-driver["reset_values"]
  reuse_values          = local.secrets-store-csi-driver["reuse_values"]
  skip_crds             = local.secrets-store-csi-driver["skip_crds"]
  verify                = local.secrets-store-csi-driver["verify"]
  values = [
    local.values_secrets-store-csi-driver,
    local.secrets-store-csi-driver["extra_values"]
  ]
  namespace = local.secrets-store-csi-driver["create_ns"] ? kubernetes_namespace.secrets-store-csi-driver.*.metadata.0.name[count.index] : local.secrets-store-csi-driver["namespace"]
}
