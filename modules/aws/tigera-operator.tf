locals {
  tigera-operator = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "tigera-operator")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "tigera-operator")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "tigera-operator")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "tigera-operator")].version
      namespace              = "tigera-operator"
      create_ns              = true
      enabled                = false
      default_network_policy = true
    },
    var.tigera-operator
  )

  values_tigera-operator = <<-VALUES
    installation:
      kubernetesProvider: EKS
    VALUES
}

resource "kubernetes_namespace" "tigera-operator" {
  count = local.tigera-operator["enabled"] && local.tigera-operator["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name                               = local.tigera-operator["namespace"]
      "${local.labels_prefix}/component" = "tigera-operator"
    }

    name = local.tigera-operator["namespace"]
  }
}

resource "helm_release" "tigera-operator" {
  count                 = local.tigera-operator["enabled"] ? 1 : 0
  repository            = local.tigera-operator["repository"]
  name                  = local.tigera-operator["name"]
  chart                 = local.tigera-operator["chart"]
  version               = local.tigera-operator["chart_version"]
  timeout               = local.tigera-operator["timeout"]
  force_update          = local.tigera-operator["force_update"]
  recreate_pods         = local.tigera-operator["recreate_pods"]
  wait                  = local.tigera-operator["wait"]
  atomic                = local.tigera-operator["atomic"]
  cleanup_on_fail       = local.tigera-operator["cleanup_on_fail"]
  dependency_update     = local.tigera-operator["dependency_update"]
  disable_crd_hooks     = local.tigera-operator["disable_crd_hooks"]
  disable_webhooks      = local.tigera-operator["disable_webhooks"]
  render_subchart_notes = local.tigera-operator["render_subchart_notes"]
  replace               = local.tigera-operator["replace"]
  reset_values          = local.tigera-operator["reset_values"]
  reuse_values          = local.tigera-operator["reuse_values"]
  skip_crds             = local.tigera-operator["skip_crds"]
  verify                = local.tigera-operator["verify"]
  values = [
    local.values_tigera-operator,
    local.tigera-operator["extra_values"]
  ]

  #TODO(bogdando): create a shared template and refer it in addons (copy-pasta until then)
  dynamic "set" {
    for_each = {
      for c, v in local.images_data.tigera-operator.containers :
      c => v if v.rewrite_values.tag != null
    }
    content {
      name  = set.value.rewrite_values.tag.name
      value = try(local.tigera-operator["containers_versions"][set.value.rewrite_values.tag.name], set.value.rewrite_values.tag.value)
    }
  }
  dynamic "set" {
    for_each = local.images_data.tigera-operator.containers
    content {
      name = set.value.rewrite_values.image.name
      value = set.value.ecr_prepare_images && set.value.source_provided ? "${
        aws_ecr_repository.this[
          format("%s.%s", split(".", set.key)[0], split(".", set.key)[2])
        ].repository_url}${set.value.rewrite_values.image.tail
        }" : set.value.ecr_prepare_images ? "${
        aws_ecr_repository.this[
          format("%s.%s", split(".", set.key)[0], split(".", set.key)[2])
        ].name
      }" : set.value.rewrite_values.image.value
    }
  }
  dynamic "set" {
    for_each = {
      for c, v in local.images_data.tigera-operator.containers :
      c => v if v.rewrite_values.registry != null
    }
    content {
      name = set.value.rewrite_values.registry.name
      # when unset, it should be replaced with the one prepared on ECR
      value = set.value.rewrite_values.registry.value != null ? set.value.rewrite_values.registry.value : split(
        "/", aws_ecr_repository.this[
          format("%s.%s", split(".", set.key)[0], split(".", set.key)[2])
        ].repository_url
      )[0]
    }
  }
  namespace = local.tigera-operator["create_ns"] ? kubernetes_namespace.tigera-operator.*.metadata.0.name[count.index] : local.tigera-operator["namespace"]

  depends_on = [
    skopeo_copy.this,
    kubectl_manifest.prometheus-operator_crds
  ]
}

resource "kubernetes_network_policy" "tigera-operator_default_deny" {
  count = local.tigera-operator["create_ns"] && local.tigera-operator["enabled"] && local.tigera-operator["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.tigera-operator.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.tigera-operator.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "tigera-operator_allow_namespace" {
  count = local.tigera-operator["create_ns"] && local.tigera-operator["enabled"] && local.tigera-operator["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.tigera-operator.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.tigera-operator.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.tigera-operator.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
