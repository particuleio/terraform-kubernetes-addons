locals {
  strimzi-kafka-operator = merge(
    local.helm_defaults,
    {
      name          = local.helm_dependencies[index(local.helm_dependencies.*.name, "strimzi-kafka-operator")].name
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "strimzi-kafka-operator")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "strimzi-kafka-operator")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "strimzi-kafka-operator")].version
      namespace     = "strimzi-kafka-operator"
      enabled       = false
      create_ns     = true
    },
    var.strimzi-kafka-operator
  )

  values_strimzi-kafka-operator = <<-VALUES
    watchAnyNamespace: true
    VALUES
}

resource "kubernetes_namespace" "strimzi-kafka-operator" {
  count = local.strimzi-kafka-operator["enabled"] && local.strimzi-kafka-operator["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name = local.strimzi-kafka-operator["namespace"]
    }

    name = local.strimzi-kafka-operator["namespace"]
  }
}

resource "helm_release" "strimzi-kafka-operator" {
  count                 = local.strimzi-kafka-operator["enabled"] ? 1 : 0
  repository            = local.strimzi-kafka-operator["repository"]
  name                  = local.strimzi-kafka-operator["name"]
  chart                 = local.strimzi-kafka-operator["chart"]
  version               = local.strimzi-kafka-operator["chart_version"]
  timeout               = local.strimzi-kafka-operator["timeout"]
  force_update          = local.strimzi-kafka-operator["force_update"]
  recreate_pods         = local.strimzi-kafka-operator["recreate_pods"]
  wait                  = local.strimzi-kafka-operator["wait"]
  atomic                = local.strimzi-kafka-operator["atomic"]
  cleanup_on_fail       = local.strimzi-kafka-operator["cleanup_on_fail"]
  dependency_update     = local.strimzi-kafka-operator["dependency_update"]
  disable_crd_hooks     = local.strimzi-kafka-operator["disable_crd_hooks"]
  disable_webhooks      = local.strimzi-kafka-operator["disable_webhooks"]
  render_subchart_notes = local.strimzi-kafka-operator["render_subchart_notes"]
  replace               = local.strimzi-kafka-operator["replace"]
  reset_values          = local.strimzi-kafka-operator["reset_values"]
  reuse_values          = local.strimzi-kafka-operator["reuse_values"]
  skip_crds             = local.strimzi-kafka-operator["skip_crds"]
  verify                = local.strimzi-kafka-operator["verify"]
  values = [
    local.values_strimzi-kafka-operator,
    local.strimzi-kafka-operator["extra_values"]
  ]
  namespace = local.strimzi-kafka-operator["create_ns"] ? kubernetes_namespace.strimzi-kafka-operator.*.metadata.0.name[count.index] : local.strimzi-kafka-operator["namespace"]
}