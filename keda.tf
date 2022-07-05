locals {
  keda = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "keda")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "keda")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "keda")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "keda")].version
      namespace              = "keda"
      create_ns              = false
      enabled                = false
      default_network_policy = true
    },
    var.keda
  )

  values_keda = <<VALUES
VALUES
}

resource "kubernetes_namespace" "keda" {
  count = local.keda["enabled"] && local.keda["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name                               = local.keda["namespace"]
      "${local.labels_prefix}/component" = "keda"
    }

    name = local.keda["namespace"]
  }
}

resource "helm_release" "keda" {
  count                 = local.keda["enabled"] ? 1 : 0
  repository            = local.keda["repository"]
  name                  = local.keda["name"]
  chart                 = local.keda["chart"]
  version               = local.keda["chart_version"]
  timeout               = local.keda["timeout"]
  force_update          = local.keda["force_update"]
  recreate_pods         = local.keda["recreate_pods"]
  wait                  = local.keda["wait"]
  atomic                = local.keda["atomic"]
  cleanup_on_fail       = local.keda["cleanup_on_fail"]
  dependency_update     = local.keda["dependency_update"]
  disable_crd_hooks     = local.keda["disable_crd_hooks"]
  disable_webhooks      = local.keda["disable_webhooks"]
  render_subchart_notes = local.keda["render_subchart_notes"]
  replace               = local.keda["replace"]
  reset_values          = local.keda["reset_values"]
  reuse_values          = local.keda["reuse_values"]
  skip_crds             = local.keda["skip_crds"]
  verify                = local.keda["verify"]
  values = [
    local.values_keda,
    local.keda["extra_values"]
  ]
  namespace = local.keda["create_ns"] ? kubernetes_namespace.keda.*.metadata.0.name[count.index] : local.keda["namespace"]

  depends_on = [
    helm_release.kube-prometheus-stack
  ]
}

resource "kubernetes_network_policy" "keda_default_deny" {
  count = local.keda["create_ns"] && local.keda["enabled"] && local.keda["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.keda.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.keda.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "keda_allow_namespace" {
  count = local.keda["create_ns"] && local.keda["enabled"] && local.keda["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.keda.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.keda.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.keda.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
