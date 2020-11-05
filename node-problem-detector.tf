locals {
  npd = merge(
    local.helm_defaults,
    {
      name                   = "node-problem-detector"
      namespace              = "node-problem-detector"
      chart                  = "node-problem-detector"
      repository             = "https://kubernetes-charts.storage.googleapis.com/"
      enabled                = false
      chart_version          = "1.7.1"
      version                = "v0.8.1"
      default_network_policy = true
    },
    var.npd
  )

  values_npd = <<VALUES
rbac:
  pspEnabled: true
image:
  tag: ${local.npd["version"]}
priorityClassName: ${local.priority_class_ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}
VALUES

}

resource "kubernetes_namespace" "node_problem_detector" {
  count = local.npd["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.npd["namespace"]
    }

    name = local.npd["namespace"]
  }
}

resource "helm_release" "node_problem_detector" {
  count                 = local.npd["enabled"] ? 1 : 0
  repository            = local.npd["repository"]
  name                  = local.npd["name"]
  chart                 = local.npd["chart"]
  version               = local.npd["chart_version"]
  timeout               = local.npd["timeout"]
  force_update          = local.npd["force_update"]
  recreate_pods         = local.npd["recreate_pods"]
  wait                  = local.npd["wait"]
  atomic                = local.npd["atomic"]
  cleanup_on_fail       = local.npd["cleanup_on_fail"]
  dependency_update     = local.npd["dependency_update"]
  disable_crd_hooks     = local.npd["disable_crd_hooks"]
  disable_webhooks      = local.npd["disable_webhooks"]
  render_subchart_notes = local.npd["render_subchart_notes"]
  replace               = local.npd["replace"]
  reset_values          = local.npd["reset_values"]
  reuse_values          = local.npd["reuse_values"]
  skip_crds             = local.npd["skip_crds"]
  verify                = local.npd["verify"]
  values = [
    local.values_npd,
    local.npd["extra_values"]
  ]
  namespace = kubernetes_namespace.node_problem_detector.*.metadata.0.name[count.index]
}

resource "kubernetes_network_policy" "npd_default_deny" {
  count = local.npd["enabled"] && local.npd["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.node_problem_detector.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.node_problem_detector.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "npd_allow_namespace" {
  count = local.npd["enabled"] && local.npd["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.node_problem_detector.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.node_problem_detector.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.node_problem_detector.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

