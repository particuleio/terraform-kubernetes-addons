locals {
  vault = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "vault")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "vault")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "vault")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "vault")].version
      namespace              = "vault"
      enabled                = false
      create_ns              = true
      default_network_policy = true
    },
    var.vault
  )

  values_vault = <<-VALUES
    VALUES
}

resource "kubernetes_namespace" "vault" {
  count = local.vault["enabled"] && local.vault["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name = local.vault["namespace"]
    }

    name = local.vault["namespace"]
  }
}

resource "helm_release" "vault" {
  count                 = local.vault["enabled"] ? 1 : 0
  repository            = local.vault["repository"]
  name                  = local.vault["name"]
  chart                 = local.vault["chart"]
  version               = local.vault["chart_version"]
  timeout               = local.vault["timeout"]
  force_update          = local.vault["force_update"]
  recreate_pods         = local.vault["recreate_pods"]
  wait                  = local.vault["wait"]
  atomic                = local.vault["atomic"]
  cleanup_on_fail       = local.vault["cleanup_on_fail"]
  dependency_update     = local.vault["dependency_update"]
  disable_crd_hooks     = local.vault["disable_crd_hooks"]
  disable_webhooks      = local.vault["disable_webhooks"]
  render_subchart_notes = local.vault["render_subchart_notes"]
  replace               = local.vault["replace"]
  reset_values          = local.vault["reset_values"]
  reuse_values          = local.vault["reuse_values"]
  skip_crds             = local.vault["skip_crds"]
  verify                = local.vault["verify"]
  values = [
    local.values_vault,
    local.vault["extra_values"]
  ]
  namespace = local.vault["create_ns"] ? kubernetes_namespace.vault.*.metadata.0.name[count.index] : local.vault["namespace"]
}

resource "kubernetes_network_policy" "vault_default_deny" {
  count = local.vault["enabled"] && local.vault["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${local.vault["namespace"]}-${local.vault["name"]}-default-deny"
    namespace = local.vault["namespace"]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "vault_allow_namespace" {
  count = local.vault["enabled"] && local.vault["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${local.vault["namespace"]}-${local.vault["name"]}-default-namespace"
    namespace = local.vault["namespace"]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = local.vault["namespace"]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
