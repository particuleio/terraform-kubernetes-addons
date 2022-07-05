locals {

  ingress-nginx = merge(
    local.helm_defaults,
    {
      name          = local.helm_dependencies[index(local.helm_dependencies.*.name, "ingress-nginx")].name
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "ingress-nginx")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "ingress-nginx")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "ingress-nginx")].version
      namespace     = "ingress-nginx"
    },
    var.ingress-nginx
  )
}

resource "kubernetes_namespace" "ingress-nginx" {
  count = local.ingress-nginx["enabled"] ? 1 : 0

  metadata {
    labels = {
      name                               = local.ingress-nginx["namespace"]
      "${local.labels_prefix}/component" = "ingress"
    }

    name = "nginx-ingress"
  }
}

resource "helm_release" "ingress-nginx" {
  count                 = local.ingress-nginx["enabled"] ? 1 : 0
  repository            = local.ingress-nginx["repository"]
  name                  = local.ingress-nginx["name"]
  chart                 = local.ingress-nginx["chart"]
  version               = local.ingress-nginx["chart_version"]
  timeout               = local.ingress-nginx["timeout"]
  force_update          = local.ingress-nginx["force_update"]
  recreate_pods         = local.ingress-nginx["recreate_pods"]
  wait                  = local.ingress-nginx["wait"]
  atomic                = local.ingress-nginx["atomic"]
  cleanup_on_fail       = local.ingress-nginx["cleanup_on_fail"]
  dependency_update     = local.ingress-nginx["dependency_update"]
  disable_crd_hooks     = local.ingress-nginx["disable_crd_hooks"]
  disable_webhooks      = local.ingress-nginx["disable_webhooks"]
  render_subchart_notes = local.ingress-nginx["render_subchart_notes"]
  replace               = local.ingress-nginx["replace"]
  reset_values          = local.ingress-nginx["reset_values"]
  reuse_values          = local.ingress-nginx["reuse_values"]
  skip_crds             = local.ingress-nginx["skip_crds"]
  verify                = local.ingress-nginx["verify"]
  values = [
    local.ingress-nginx["extra_values"],
  ]
  namespace = kubernetes_namespace.ingress-nginx.*.metadata.0.name[count.index]

  #The ingress controller needs to be scheduled on a Linux node. Windows Server nodes shouldn't run the ingress controller
  set {
    name  = "defaultBackend.nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }

}
