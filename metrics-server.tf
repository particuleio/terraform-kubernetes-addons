locals {
  metrics-server = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "metrics-server")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "metrics-server")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "metrics-server")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "metrics-server")].version
      namespace              = "metrics-server"
      enabled                = false
      default_network_policy = true
      allowed_cidrs          = ["0.0.0.0/0"]
    },
    var.metrics-server
  )

  values_metrics-server = <<VALUES
apiService:
  create: true
priorityClassName: ${local.priority-class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
VALUES

}

resource "kubernetes_namespace" "metrics-server" {
  count = local.metrics-server["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.metrics-server["namespace"]
    }

    name = local.metrics-server["namespace"]
  }
}

resource "helm_release" "metrics-server" {
  count                 = local.metrics-server["enabled"] ? 1 : 0
  repository            = local.metrics-server["repository"]
  name                  = local.metrics-server["name"]
  chart                 = local.metrics-server["chart"]
  version               = local.metrics-server["chart_version"]
  timeout               = local.metrics-server["timeout"]
  force_update          = local.metrics-server["force_update"]
  recreate_pods         = local.metrics-server["recreate_pods"]
  wait                  = local.metrics-server["wait"]
  atomic                = local.metrics-server["atomic"]
  cleanup_on_fail       = local.metrics-server["cleanup_on_fail"]
  dependency_update     = local.metrics-server["dependency_update"]
  disable_crd_hooks     = local.metrics-server["disable_crd_hooks"]
  disable_webhooks      = local.metrics-server["disable_webhooks"]
  render_subchart_notes = local.metrics-server["render_subchart_notes"]
  replace               = local.metrics-server["replace"]
  reset_values          = local.metrics-server["reset_values"]
  reuse_values          = local.metrics-server["reuse_values"]
  skip_crds             = local.metrics-server["skip_crds"]
  verify                = local.metrics-server["verify"]
  values = [
    local.values_metrics-server,
    local.metrics-server["extra_values"]
  ]

  #TODO(bogdando): create a shared template and refer it in addons (copy-pasta until then)
  dynamic "set" {
    for_each = {
      for c, v in local.images_data.metrics-server.containers :
      c => v if v.rewrite_values.tag != null
    }
    content {
      name  = set.value.rewrite_values.tag.name
      value = try(local.metrics-server["containers_versions"][set.value.rewrite_values.tag.name], set.value.rewrite_values.tag.value)
    }
  }
  dynamic "set" {
    for_each = local.images_data.metrics-server.containers
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
      for c, v in local.images_data.metrics-server.containers :
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

  namespace = kubernetes_namespace.metrics-server.*.metadata.0.name[count.index]

  depends_on = [
    skopeo_copy.this
  ]
}

resource "kubernetes_network_policy" "metrics-server_default_deny" {
  count = local.metrics-server["enabled"] && local.metrics-server["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.metrics-server.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.metrics-server.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "metrics-server_allow_namespace" {
  count = local.metrics-server["enabled"] && local.metrics-server["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.metrics-server.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.metrics-server.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.metrics-server.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "metrics-server_allow_control_plane" {
  count = local.metrics-server["enabled"] && local.metrics-server["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.metrics-server.*.metadata.0.name[count.index]}-allow-control-plane"
    namespace = kubernetes_namespace.metrics-server.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "app.kubernetes.io/name"
        operator = "In"
        values   = ["metrics-server"]
      }
    }

    ingress {
      ports {
        port     = "4443"
        protocol = "TCP"
      }

      dynamic "from" {
        for_each = local.metrics-server["allowed_cidrs"]
        content {
          ip_block {
            cidr = from.value
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
