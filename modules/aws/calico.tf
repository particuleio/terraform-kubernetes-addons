locals {

  calico = merge(
    local.helm_defaults,
    {
      name          = local.helm_dependencies[index(local.helm_dependencies.*.name, "aws-calico")].name
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "aws-calico")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "aws-calico")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "aws-calico")].version
      namespace     = "kube-system"
      enabled       = false
      create_ns     = false

    },
    var.calico
  )

  values_calico = <<VALUES
VALUES

}

resource "kubernetes_namespace" "calico" {
  count = local.calico["enabled"] && local.calico["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name = local.calico["namespace"]
    }

    name = local.calico["namespace"]
  }
}

resource "helm_release" "calico" {
  count                 = local.calico["enabled"] ? 1 : 0
  repository            = local.calico["repository"]
  name                  = local.calico["name"]
  chart                 = local.calico["chart"]
  version               = local.calico["chart_version"]
  timeout               = local.calico["timeout"]
  force_update          = local.calico["force_update"]
  recreate_pods         = local.calico["recreate_pods"]
  wait                  = local.calico["wait"]
  atomic                = local.calico["atomic"]
  cleanup_on_fail       = local.calico["cleanup_on_fail"]
  dependency_update     = local.calico["dependency_update"]
  disable_crd_hooks     = local.calico["disable_crd_hooks"]
  disable_webhooks      = local.calico["disable_webhooks"]
  render_subchart_notes = local.calico["render_subchart_notes"]
  replace               = local.calico["replace"]
  reset_values          = local.calico["reset_values"]
  reuse_values          = local.calico["reuse_values"]
  skip_crds             = local.calico["skip_crds"]
  verify                = local.calico["verify"]
  values = [
    local.values_calico,
    local.calico["extra_values"]
  ]
  namespace = local.calico["create_ns"] ? kubernetes_namespace.calico.*.metadata.0.name[count.index] : local.calico["namespace"]
}