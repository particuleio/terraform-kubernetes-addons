locals {

  cert-manager-csi-driver = merge(
    local.helm_defaults,
    {
      name          = local.helm_dependencies[index(local.helm_dependencies.*.name, "cert-manager-csi-driver")].name
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "cert-manager-csi-driver")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "cert-manager-csi-driver")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "cert-manager-csi-driver")].version
      enabled       = local.cert-manager.csi_driver
      namespace     = local.cert-manager.namespace
    },
    var.cert-manager-csi-driver
  )

  values_cert-manager-csi-driver = <<VALUES
tolerations:
  - operator: "Exists"
VALUES

}

resource "helm_release" "cert-manager-csi-driver" {
  count                 = local.cert-manager-csi-driver["enabled"] ? 1 : 0
  repository            = local.cert-manager-csi-driver["repository"]
  name                  = local.cert-manager-csi-driver["name"]
  chart                 = local.cert-manager-csi-driver["chart"]
  version               = local.cert-manager-csi-driver["chart_version"]
  timeout               = local.cert-manager-csi-driver["timeout"]
  force_update          = local.cert-manager-csi-driver["force_update"]
  recreate_pods         = local.cert-manager-csi-driver["recreate_pods"]
  wait                  = local.cert-manager-csi-driver["wait"]
  atomic                = local.cert-manager-csi-driver["atomic"]
  cleanup_on_fail       = local.cert-manager-csi-driver["cleanup_on_fail"]
  dependency_update     = local.cert-manager-csi-driver["dependency_update"]
  disable_crd_hooks     = local.cert-manager-csi-driver["disable_crd_hooks"]
  disable_webhooks      = local.cert-manager-csi-driver["disable_webhooks"]
  render_subchart_notes = local.cert-manager-csi-driver["render_subchart_notes"]
  replace               = local.cert-manager-csi-driver["replace"]
  reset_values          = local.cert-manager-csi-driver["reset_values"]
  reuse_values          = local.cert-manager-csi-driver["reuse_values"]
  skip_crds             = local.cert-manager-csi-driver["skip_crds"]
  verify                = local.cert-manager-csi-driver["verify"]
  values = [
    local.values_cert-manager-csi-driver,
    local.cert-manager-csi-driver["extra_values"]
  ]
  namespace = local.cert-manager-csi-driver.namespace

  depends_on = [
    helm_release.cert-manager
  ]
}
