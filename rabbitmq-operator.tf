locals {
  rabbitmq-operator = merge(
    local.helm_defaults,
    {
      name          = local.helm_dependencies[index(local.helm_dependencies.*.name, "rabbitmq-cluster-operator")].name
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "rabbitmq-cluster-operator")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "rabbitmq-cluster-operator")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "rabbitmq-cluster-operator")].version
      namespace     = "rabbitmq-operator"
      create_ns     = true
      enabled       = false
    },
    var.rabbitmq-operator
  )

  values_rabbitmq-operator = <<VALUES
VALUES
}

resource "kubernetes_namespace" "rabbitmq-operator" {
  count = local.rabbitmq-operator["enabled"] && local.rabbitmq-operator["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name                               = local.rabbitmq-operator["namespace"]
      "${local.labels_prefix}/component" = "rabbitmq-operator"
    }

    name = local.rabbitmq-operator["namespace"]
  }
}

resource "helm_release" "rabbitmq-operator" {
  count                 = local.rabbitmq-operator["enabled"] ? 1 : 0
  repository            = local.rabbitmq-operator["repository"]
  name                  = local.rabbitmq-operator["name"]
  chart                 = local.rabbitmq-operator["chart"]
  version               = local.rabbitmq-operator["chart_version"]
  timeout               = local.rabbitmq-operator["timeout"]
  force_update          = local.rabbitmq-operator["force_update"]
  recreate_pods         = local.rabbitmq-operator["recreate_pods"]
  wait                  = local.rabbitmq-operator["wait"]
  atomic                = local.rabbitmq-operator["atomic"]
  cleanup_on_fail       = local.rabbitmq-operator["cleanup_on_fail"]
  dependency_update     = local.rabbitmq-operator["dependency_update"]
  disable_crd_hooks     = local.rabbitmq-operator["disable_crd_hooks"]
  disable_webhooks      = local.rabbitmq-operator["disable_webhooks"]
  render_subchart_notes = local.rabbitmq-operator["render_subchart_notes"]
  replace               = local.rabbitmq-operator["replace"]
  reset_values          = local.rabbitmq-operator["reset_values"]
  reuse_values          = local.rabbitmq-operator["reuse_values"]
  skip_crds             = local.rabbitmq-operator["skip_crds"]
  verify                = local.rabbitmq-operator["verify"]
  values = [
    local.values_rabbitmq-operator,
    local.rabbitmq-operator["extra_values"]
  ]
  namespace = local.rabbitmq-operator["create_ns"] ? kubernetes_namespace.rabbitmq-operator.*.metadata.0.name[count.index] : local.rabbitmq-operator["namespace"]

  depends_on = [
    helm_release.kube-prometheus-stack
  ]
}