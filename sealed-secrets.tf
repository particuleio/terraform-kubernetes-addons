locals {

  sealed_secrets = merge(
    local.helm_defaults,
    {
      name                   = "sealed-secrets"
      namespace              = "sealed-secrets"
      chart                  = "sealed-secrets"
      repository             = "https://kubernetes-charts.storage.googleapis.com/"
      enabled                = false
      chart_version          = "1.10.3"
      version                = "v0.12.4"
      default_network_policy = true
    },
    var.sealed_secrets
  )

  values_sealed_secrets = <<VALUES
rbac:
  pspEnabled: true
image:
  tag: ${local.sealed_secrets["version"]}
priorityClassName: ${local.priority_class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
VALUES

}

resource "kubernetes_namespace" "sealed_secrets" {
  count = local.sealed_secrets["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.sealed_secrets["namespace"]
    }

    name = local.sealed_secrets["namespace"]
  }
}

resource "helm_release" "sealed_secrets" {
  count                 = local.sealed_secrets["enabled"] ? 1 : 0
  repository            = local.sealed_secrets["repository"]
  name                  = local.sealed_secrets["name"]
  chart                 = local.sealed_secrets["chart"]
  version               = local.sealed_secrets["chart_version"]
  timeout               = local.sealed_secrets["timeout"]
  force_update          = local.sealed_secrets["force_update"]
  recreate_pods         = local.sealed_secrets["recreate_pods"]
  wait                  = local.sealed_secrets["wait"]
  atomic                = local.sealed_secrets["atomic"]
  cleanup_on_fail       = local.sealed_secrets["cleanup_on_fail"]
  dependency_update     = local.sealed_secrets["dependency_update"]
  disable_crd_hooks     = local.sealed_secrets["disable_crd_hooks"]
  disable_webhooks      = local.sealed_secrets["disable_webhooks"]
  render_subchart_notes = local.sealed_secrets["render_subchart_notes"]
  replace               = local.sealed_secrets["replace"]
  reset_values          = local.sealed_secrets["reset_values"]
  reuse_values          = local.sealed_secrets["reuse_values"]
  skip_crds             = local.sealed_secrets["skip_crds"]
  verify                = local.sealed_secrets["verify"]
  values = [
    local.values_sealed_secrets,
    local.sealed_secrets["extra_values"]
  ]
  namespace = kubernetes_namespace.sealed_secrets.*.metadata.0.name[count.index]
}

resource "kubernetes_network_policy" "sealed_secrets_default_deny" {
  count = local.sealed_secrets["enabled"] && local.sealed_secrets["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.sealed_secrets.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.sealed_secrets.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "sealed_secrets_allow_namespace" {
  count = local.sealed_secrets["enabled"] && local.sealed_secrets["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.sealed_secrets.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.sealed_secrets.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.sealed_secrets.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

