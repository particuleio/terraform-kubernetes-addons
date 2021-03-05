locals {

  thanos-memcached = merge(
    local.helm_defaults,
    {
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "memcached")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "memcached")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "memcached")].version
      name          = "thanos-memcached"
      namespace     = local.thanos["namespace"]
      enabled       = false
    },
    var.thanos-memcached
  )

  values_thanos-memcached = <<-VALUES
    architecture: "high-availability"
    replicaCount: 2
    podAntiAffinityPreset: hard
    metrics:
      enabled: ${local.kube-prometheus-stack["enabled"]}
      serviceMonitor:
        enabled: ${local.kube-prometheus-stack["enabled"]}
    VALUES
}

resource "helm_release" "thanos-memcached" {
  count                 = local.thanos-memcached["enabled"] ? 1 : 0
  repository            = local.thanos-memcached["repository"]
  name                  = local.thanos-memcached["name"]
  chart                 = local.thanos-memcached["chart"]
  version               = local.thanos-memcached["chart_version"]
  timeout               = local.thanos-memcached["timeout"]
  force_update          = local.thanos-memcached["force_update"]
  recreate_pods         = local.thanos-memcached["recreate_pods"]
  wait                  = local.thanos-memcached["wait"]
  atomic                = local.thanos-memcached["atomic"]
  cleanup_on_fail       = local.thanos-memcached["cleanup_on_fail"]
  dependency_update     = local.thanos-memcached["dependency_update"]
  disable_crd_hooks     = local.thanos-memcached["disable_crd_hooks"]
  disable_webhooks      = local.thanos-memcached["disable_webhooks"]
  render_subchart_notes = local.thanos-memcached["render_subchart_notes"]
  replace               = local.thanos-memcached["replace"]
  reset_values          = local.thanos-memcached["reset_values"]
  reuse_values          = local.thanos-memcached["reuse_values"]
  skip_crds             = local.thanos-memcached["skip_crds"]
  verify                = local.thanos-memcached["verify"]
  values = compact([
    local.values_thanos-memcached,
    local.thanos-memcached["extra_values"]
  ])
  namespace = local.thanos-memcached["namespace"]

  depends_on = [
    helm_release.kube-prometheus-stack,
  ]
}
