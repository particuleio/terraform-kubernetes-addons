locals {
  linkerd2-cni = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "linkerd2-cni")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "linkerd2-cni")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "linkerd2-cni")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "linkerd2-cni")].version
      namespace              = "linkerd-cni"
      create_ns              = true
      enabled                = local.linkerd.enabled
      cni_conflist_filename  = "10-calico.conflist"
      default_network_policy = true
    },
    var.linkerd2-cni
  )

  values_linkerd2-cni = <<VALUES
    VALUES
}

resource "kubernetes_namespace" "linkerd2-cni" {
  count = local.linkerd2-cni["enabled"] && local.linkerd2-cni["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name                                  = local.linkerd2-cni["namespace"]
      "config.linkerd.io/admission-webhook" = "disabled"
      "linkerd.io/cni-resource"             = "true"
    }

    annotations = {
      "linkerd.io/inject" = "disabled"
    }

    name = local.linkerd2-cni["namespace"]
  }
}

resource "helm_release" "linkerd2-cni" {
  count                 = local.linkerd2-cni["enabled"] ? 1 : 0
  repository            = local.linkerd2-cni["repository"]
  name                  = local.linkerd2-cni["name"]
  chart                 = local.linkerd2-cni["chart"]
  version               = local.linkerd2-cni["chart_version"]
  timeout               = local.linkerd2-cni["timeout"]
  force_update          = local.linkerd2-cni["force_update"]
  recreate_pods         = local.linkerd2-cni["recreate_pods"]
  wait                  = local.linkerd2-cni["wait"]
  atomic                = local.linkerd2-cni["atomic"]
  cleanup_on_fail       = local.linkerd2-cni["cleanup_on_fail"]
  dependency_update     = local.linkerd2-cni["dependency_update"]
  disable_crd_hooks     = local.linkerd2-cni["disable_crd_hooks"]
  disable_webhooks      = local.linkerd2-cni["disable_webhooks"]
  render_subchart_notes = local.linkerd2-cni["render_subchart_notes"]
  replace               = local.linkerd2-cni["replace"]
  reset_values          = local.linkerd2-cni["reset_values"]
  reuse_values          = local.linkerd2-cni["reuse_values"]
  skip_crds             = local.linkerd2-cni["skip_crds"]
  verify                = local.linkerd2-cni["verify"]
  values = [
    local.values_linkerd2-cni,
    local.linkerd2-cni["extra_values"]
  ]
  namespace = local.linkerd2-cni["create_ns"] ? kubernetes_namespace.linkerd2-cni.*.metadata.0.name[count.index] : local.linkerd2-cni["namespace"]
}

resource "kubernetes_network_policy" "linkerd2-cni_default_deny" {
  count = local.linkerd2-cni["create_ns"] && local.linkerd2-cni["enabled"] && local.linkerd2-cni["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.linkerd2-cni.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.linkerd2-cni.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "linkerd2-cni_allow_namespace" {
  count = local.linkerd2-cni["create_ns"] && local.linkerd2-cni["enabled"] && local.linkerd2-cni["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.linkerd2-cni.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.linkerd2-cni.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.linkerd2-cni.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
