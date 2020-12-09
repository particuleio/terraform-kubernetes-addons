locals {
  huxjira = merge(
    local.helm_defaults,
    {
      name                   = "huxjira"
      namespace              = "atlassian"
      chart                  = "huxjira"
      repository             = "https://raw.githubusercontent.com/Deloittehux/techops-helm-charts/master/"
      enabled                = false
      chart_version          = "0.1.0"
      version                = "8.9.1"
      default_network_policy = true
    },
    var.huxjira
  )

  values_huxjira = <<VALUES
hub: istio
tag: ${local.huxjira["version"]}-distroless
VALUES
}

resource "kubernetes_namespace" "huxjira" {
  count = local.huxjira["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.huxjira["namespace"]
    }

    name = local.huxjira["namespace"]
  }
}

resource "helm_release" "huxjira" {
  count                 = local.huxjira["enabled"] ? 1 : 0
  repository            = local.huxjira["repository"]
  name                  = local.huxjira["name"]
  chart                 = local.huxjira["chart"]
  version               = local.huxjira["chart_version"]
  timeout               = local.huxjira["timeout"]
  force_update          = local.huxjira["force_update"]
  recreate_pods         = local.huxjira["recreate_pods"]
  wait                  = local.huxjira["wait"]
  atomic                = local.huxjira["atomic"]
  cleanup_on_fail       = local.huxjira["cleanup_on_fail"]
  dependency_update     = local.huxjira["dependency_update"]
  disable_crd_hooks     = local.huxjira["disable_crd_hooks"]
  disable_webhooks      = local.huxjira["disable_webhooks"]
  render_subchart_notes = local.huxjira["render_subchart_notes"]
  replace               = local.huxjira["replace"]
  reset_values          = local.huxjira["reset_values"]
  reuse_values          = local.huxjira["reuse_values"]
  skip_crds             = local.huxjira["skip_crds"]
  verify                = local.huxjira["verify"]
  values = [
    local.values_huxjira,
    local.huxjira["extra_values"]
  ]
  namespace = kubernetes_namespace.huxjira.*.metadata.0.name[count.index]
}

resource "kubernetes_network_policy" "huxjira_default_deny" {
  count = local.huxjira["enabled"] && local.huxjira["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.huxjira.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.huxjira.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "huxjira_allow_namespace" {
  count = local.huxjira["enabled"] && local.huxjira["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.huxjira.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.huxjira.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.huxjira.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
