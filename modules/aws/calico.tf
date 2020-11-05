locals {

  calico = merge(
    local.helm_defaults,
    {
      name                   = "calico"
      namespace              = "kube-system"
      chart                  = "aws-calico"
      repository             = "https://aws.github.io/eks-charts"
      enabled                = false
      chart_version          = "0.3.1"
      version                = "v3.13.4"
      default_network_policy = true
      create_ns              = false

    },
    var.calico
  )

  values_calico = <<VALUES
VALUES

}

resource "kubernetes_namespace" "calico" {
  count = local.calico["enabled"] && local.calico["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name = local.calico["namespace"]
    }

    name = local.calico["namespace"]
  }
}

resource "helm_release" "calico" {
  count                 = local.calico["enabled"] ? 1 : 0
  repository            = local.calico["repository"]
  name                  = local.calico["name"]
  chart                 = local.calico["chart"]
  version               = local.calico["chart_version"]
  timeout               = local.calico["timeout"]
  force_update          = local.calico["force_update"]
  recreate_pods         = local.calico["recreate_pods"]
  wait                  = local.calico["wait"]
  atomic                = local.calico["atomic"]
  cleanup_on_fail       = local.calico["cleanup_on_fail"]
  dependency_update     = local.calico["dependency_update"]
  disable_crd_hooks     = local.calico["disable_crd_hooks"]
  disable_webhooks      = local.calico["disable_webhooks"]
  render_subchart_notes = local.calico["render_subchart_notes"]
  replace               = local.calico["replace"]
  reset_values          = local.calico["reset_values"]
  reuse_values          = local.calico["reuse_values"]
  skip_crds             = local.calico["skip_crds"]
  verify                = local.calico["verify"]
  values = [
    local.values_calico,
    local.calico["extra_values"]
  ]
  namespace = local.calico["create_ns"] ? kubernetes_namespace.calico.*.metadata.0.name[count.index] : local.calico["namespace"]
}

resource "kubernetes_network_policy" "calico_default_deny" {
  count = local.calico["enabled"] && local.calico["default_network_policy"] && local.calico["create_ns"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.calico.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.calico.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "calico_allow_namespace" {
  count = local.calico["enabled"] && local.calico["default_network_policy"] && local.calico["create_ns"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.calico.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.calico.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.calico.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
