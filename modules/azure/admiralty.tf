locals {
  admiralty = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies[0].name, "admiralty")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies[0].name, "admiralty")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies[0].name, "admiralty")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies[0].name, "admiralty")].version
      namespace              = "admiralty"
      enabled                = false
      create_ns              = true
      default_network_policy = true
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
  namespace = local.admiralty["create_ns"] ? kubernetes_namespace.admiralty[0].metadata[0].name[count.index] : local.admiralty["namespace"]
}

resource "kubernetes_network_policy" "admiralty_default_deny" {
  count = local.admiralty["enabled"] && local.admiralty["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${local.admiralty["namespace"]}-${local.admiralty["name"]}-default-deny"
    namespace = local.admiralty["namespace"]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "admiralty_allow_namespace" {
  count = local.admiralty["enabled"] && local.admiralty["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${local.admiralty["namespace"]}-${local.admiralty["name"]}-default-namespace"
    namespace = local.admiralty["namespace"]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = local.admiralty["namespace"]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
