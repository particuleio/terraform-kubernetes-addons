locals {
  tempo = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "tempo")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "tempo")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "tempo")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "tempo")].version
      namespace              = "monitoring"
      enabled                = false
      default_network_policy = true
    },
    var.tempo
  )

  values_tempo = <<-VALUES
    VALUES
}

resource "helm_release" "tempo" {
  count                 = local.tempo["enabled"] ? 1 : 0
  repository            = local.tempo["repository"]
  name                  = local.tempo["name"]
  chart                 = local.tempo["chart"]
  version               = local.tempo["chart_version"]
  timeout               = local.tempo["timeout"]
  force_update          = local.tempo["force_update"]
  recreate_pods         = local.tempo["recreate_pods"]
  wait                  = local.tempo["wait"]
  atomic                = local.tempo["atomic"]
  cleanup_on_fail       = local.tempo["cleanup_on_fail"]
  dependency_update     = local.tempo["dependency_update"]
  disable_crd_hooks     = local.tempo["disable_crd_hooks"]
  disable_webhooks      = local.tempo["disable_webhooks"]
  render_subchart_notes = local.tempo["render_subchart_notes"]
  replace               = local.tempo["replace"]
  reset_values          = local.tempo["reset_values"]
  reuse_values          = local.tempo["reuse_values"]
  skip_crds             = local.tempo["skip_crds"]
  verify                = local.tempo["verify"]
  namespace             = local.tempo["namespace"]
  values = [
    local.values_tempo,
    local.tempo["extra_values"]
  ]

  depends_on = [
    helm_release.kube-prometheus-stack
  ]
}

resource "kubernetes_network_policy" "tempo_default_deny" {
  count = local.tempo["enabled"] && local.tempo["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${local.tempo["namespace"]}-${local.tempo["name"]}-default-deny"
    namespace = local.tempo["namespace"]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "tempo_allow_namespace" {
  count = local.tempo["enabled"] && local.tempo["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${local.tempo["namespace"]}-${local.tempo["name"]}-default-namespace"
    namespace = local.tempo["namespace"]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = local.tempo["namespace"]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
