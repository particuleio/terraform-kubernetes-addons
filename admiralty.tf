locals {
  admiralty = merge(
    local.helm_defaults,
    {
      name          = local.helm_dependencies[index(local.helm_dependencies.*.name, "admiralty")].name
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "admiralty")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "admiralty")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "admiralty")].version
      namespace     = "admiralty"
      enabled       = false
      create_ns     = true
    },
    var.admiralty
  )

  values_admiralty = <<-VALUES
    VALUES
}

resource "kubernetes_namespace" "admiralty" {
  count = local.admiralty["enabled"] && local.admiralty["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name = local.admiralty["namespace"]
    }

    name = local.admiralty["namespace"]
  }
}

resource "helm_release" "admiralty" {
  count                 = local.admiralty["enabled"] ? 1 : 0
  repository            = local.admiralty["repository"]
  name                  = local.admiralty["name"]
  chart                 = local.admiralty["chart"]
  version               = local.admiralty["chart_version"]
  timeout               = local.admiralty["timeout"]
  force_update          = local.admiralty["force_update"]
  recreate_pods         = local.admiralty["recreate_pods"]
  wait                  = local.admiralty["wait"]
  atomic                = local.admiralty["atomic"]
  cleanup_on_fail       = local.admiralty["cleanup_on_fail"]
  dependency_update     = local.admiralty["dependency_update"]
  disable_crd_hooks     = local.admiralty["disable_crd_hooks"]
  disable_webhooks      = local.admiralty["disable_webhooks"]
  render_subchart_notes = local.admiralty["render_subchart_notes"]
  replace               = local.admiralty["replace"]
  reset_values          = local.admiralty["reset_values"]
  reuse_values          = local.admiralty["reuse_values"]
  skip_crds             = local.admiralty["skip_crds"]
  verify                = local.admiralty["verify"]
  values = [
    local.values_admiralty,
    local.admiralty["extra_values"]
  ]
  namespace = local.admiralty["create_ns"] ? kubernetes_namespace.admiralty.*.metadata.0.name[count.index] : local.admiralty["namespace"]
}
