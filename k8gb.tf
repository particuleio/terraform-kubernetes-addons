locals {
  k8gb = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies[0].name, "k8gb")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies[0].name, "k8gb")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies[0].name, "k8gb")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies[0].name, "k8gb")].version
      namespace              = "k8gb"
      enabled                = false
      create_ns              = true
      default_network_policy = false
    },
    var.k8gb
  )

  values_k8gb = <<-VALUES
    VALUES
}

resource "kubernetes_namespace" "k8gb" {
  count = local.k8gb["enabled"] && local.k8gb["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name = local.k8gb["namespace"]
    }

    name = local.k8gb["namespace"]
  }
}

resource "helm_release" "k8gb" {
  count                 = local.k8gb["enabled"] ? 1 : 0
  repository            = local.k8gb["repository"]
  name                  = local.k8gb["name"]
  chart                 = local.k8gb["chart"]
  version               = local.k8gb["chart_version"]
  timeout               = local.k8gb["timeout"]
  force_update          = local.k8gb["force_update"]
  recreate_pods         = local.k8gb["recreate_pods"]
  wait                  = local.k8gb["wait"]
  atomic                = local.k8gb["atomic"]
  cleanup_on_fail       = local.k8gb["cleanup_on_fail"]
  dependency_update     = local.k8gb["dependency_update"]
  disable_crd_hooks     = local.k8gb["disable_crd_hooks"]
  disable_webhooks      = local.k8gb["disable_webhooks"]
  render_subchart_notes = local.k8gb["render_subchart_notes"]
  replace               = local.k8gb["replace"]
  reset_values          = local.k8gb["reset_values"]
  reuse_values          = local.k8gb["reuse_values"]
  skip_crds             = local.k8gb["skip_crds"]
  verify                = local.k8gb["verify"]
  values = [
    local.values_k8gb,
    local.k8gb["extra_values"]
  ]
  namespace = local.k8gb["create_ns"] ? kubernetes_namespace.k8gb[0].metadata[0].name[count.index] : local.k8gb["namespace"]
}

resource "kubernetes_network_policy" "k8gb_default_deny" {
  count = local.k8gb["enabled"] && local.k8gb["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${local.k8gb["namespace"]}-${local.k8gb["name"]}-default-deny"
    namespace = local.k8gb["namespace"]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "k8gb_allow_namespace" {
  count = local.k8gb["enabled"] && local.k8gb["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${local.k8gb["namespace"]}-${local.k8gb["name"]}-default-namespace"
    namespace = local.k8gb["namespace"]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = local.k8gb["namespace"]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
