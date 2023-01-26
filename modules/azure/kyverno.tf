locals {
  kyverno = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies[0].name, "kyverno")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies[0].name, "kyverno")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies[0].name, "kyverno")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies[0].name, "kyverno")].version
      namespace              = "kyverno"
      create_ns              = false
      enabled                = false
      default_network_policy = true
    },
    var.kyverno
  )

  values_kyverno = <<VALUES
VALUES

  kyverno-crds = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies[0].name, "kyverno-crds")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies[0].name, "kyverno-crds")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies[0].name, "kyverno-crds")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies[0].name, "kyverno-crds")].version
      namespace              = "kyverno"
      create_ns              = false
      enabled                = local.kyverno["enabled"] && !local.kyverno["skip_crds"]
      default_network_policy = true
    },
  )
}

resource "kubernetes_namespace" "kyverno" {
  count = local.kyverno["enabled"] && local.kyverno["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name                               = local.kyverno["namespace"]
      "${local.labels_prefix}/component" = "kyverno"
    }

    name = local.kyverno["namespace"]
  }
}

resource "helm_release" "kyverno" {
  count                 = local.kyverno["enabled"] ? 1 : 0
  repository            = local.kyverno["repository"]
  name                  = local.kyverno["name"]
  chart                 = local.kyverno["chart"]
  version               = local.kyverno["chart_version"]
  timeout               = local.kyverno["timeout"]
  force_update          = local.kyverno["force_update"]
  recreate_pods         = local.kyverno["recreate_pods"]
  wait                  = local.kyverno["wait"]
  atomic                = local.kyverno["atomic"]
  cleanup_on_fail       = local.kyverno["cleanup_on_fail"]
  dependency_update     = local.kyverno["dependency_update"]
  disable_crd_hooks     = local.kyverno["disable_crd_hooks"]
  disable_webhooks      = local.kyverno["disable_webhooks"]
  render_subchart_notes = local.kyverno["render_subchart_notes"]
  replace               = local.kyverno["replace"]
  reset_values          = local.kyverno["reset_values"]
  reuse_values          = local.kyverno["reuse_values"]
  skip_crds             = local.kyverno["skip_crds"]
  verify                = local.kyverno["verify"]
  values = [
    local.values_kyverno,
    local.kyverno["extra_values"]
  ]
  namespace = local.kyverno["create_ns"] ? kubernetes_namespace.kyverno[0].metadata[0].name[count.index] : local.kyverno["namespace"]

  depends_on = [
    kubectl_manifest.prometheus-operator_crds,
    helm_release.kyverno-crds
  ]
}

resource "helm_release" "kyverno-crds" {
  count                 = local.kyverno["enabled"] && !local.kyverno["skip_crds"] ? 1 : 0
  repository            = local.kyverno["repository"]
  name                  = local.kyverno-crds["name"]
  chart                 = local.kyverno-crds["chart"]
  version               = local.kyverno-crds["chart_version"]
  timeout               = local.kyverno["timeout"]
  force_update          = local.kyverno["force_update"]
  recreate_pods         = local.kyverno["recreate_pods"]
  wait                  = local.kyverno["wait"]
  atomic                = local.kyverno["atomic"]
  cleanup_on_fail       = local.kyverno["cleanup_on_fail"]
  dependency_update     = local.kyverno["dependency_update"]
  disable_crd_hooks     = local.kyverno["disable_crd_hooks"]
  disable_webhooks      = local.kyverno["disable_webhooks"]
  render_subchart_notes = local.kyverno["render_subchart_notes"]
  replace               = local.kyverno["replace"]
  reset_values          = local.kyverno["reset_values"]
  reuse_values          = local.kyverno["reuse_values"]
  skip_crds             = local.kyverno["skip_crds"]
  verify                = local.kyverno["verify"]
  values = [
    local.values_kyverno,
    local.kyverno["extra_values"]
  ]
  namespace = local.kyverno["create_ns"] ? kubernetes_namespace.kyverno[0].metadata[0].name[count.index] : local.kyverno["namespace"]
}

resource "kubernetes_network_policy" "kyverno_default_deny" {
  count = local.kyverno["create_ns"] && local.kyverno["enabled"] && local.kyverno["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.kyverno[0].metadata[0].name[count.index]}-default-deny"
    namespace = kubernetes_namespace.kyverno[0].metadata[0].name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "kyverno_allow_namespace" {
  count = local.kyverno["create_ns"] && local.kyverno["enabled"] && local.kyverno["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.kyverno[0].metadata[0].name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.kyverno[0].metadata[0].name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.kyverno[0].metadata[0].name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
