locals {
  linkerd-viz = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies[0].name, "linkerd-viz")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies[0].name, "linkerd-viz")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies[0].name, "linkerd-viz")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies[0].name, "linkerd-viz")].version
      namespace              = "linkerd-viz"
      create_ns              = true
      enabled                = local.linkerd2.enabled
      default_network_policy = true
      ha                     = true
    },
    var.linkerd-viz
  )

  values_linkerd-viz = <<VALUES
namespace: ${local.linkerd-viz.namespace}
installNamespace: false
VALUES

  values_linkerd-viz_ha = <<VALUES

enablePodAntiAffinity: true

resources: &ha_resources
  cpu: &ha_resources_cpu
    limit: ""
    request: 100m
  memory:
    limit: 250Mi
    request: 50Mi

# tap configuration
tap:
  replicas: 3
  resources: *ha_resources

# web configuration
dashboard:
  resources: *ha_resources

# grafana configuration
grafana:
  resources:
    cpu: *ha_resources_cpu
    memory:
      limit: 1024Mi
      request: 50Mi

# prometheus configuration
prometheus:
  resources:
    cpu:
      limit: ""
      request: 300m
    memory:
      limit: 8192Mi
      request: 300Mi
VALUES
}

resource "kubernetes_namespace" "linkerd-viz" {
  count = local.linkerd-viz["enabled"] && local.linkerd-viz["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name                   = local.linkerd-viz["namespace"]
      "linkerd.io/extension" = "viz"
    }

    annotations = {
      "linkerd.io/inject"             = "enabled"
      "config.linkerd.io/proxy-await" = "enabled"
    }

    name = local.linkerd-viz["namespace"]
  }
}

resource "helm_release" "linkerd-viz" {
  count                 = local.linkerd-viz["enabled"] ? 1 : 0
  repository            = local.linkerd-viz["repository"]
  name                  = local.linkerd-viz["name"]
  chart                 = local.linkerd-viz["chart"]
  version               = local.linkerd-viz["chart_version"]
  timeout               = local.linkerd-viz["timeout"]
  force_update          = local.linkerd-viz["force_update"]
  recreate_pods         = local.linkerd-viz["recreate_pods"]
  wait                  = local.linkerd-viz["wait"]
  atomic                = local.linkerd-viz["atomic"]
  cleanup_on_fail       = local.linkerd-viz["cleanup_on_fail"]
  dependency_update     = local.linkerd-viz["dependency_update"]
  disable_crd_hooks     = local.linkerd-viz["disable_crd_hooks"]
  disable_webhooks      = local.linkerd-viz["disable_webhooks"]
  render_subchart_notes = local.linkerd-viz["render_subchart_notes"]
  replace               = local.linkerd-viz["replace"]
  reset_values          = local.linkerd-viz["reset_values"]
  reuse_values          = local.linkerd-viz["reuse_values"]
  skip_crds             = local.linkerd-viz["skip_crds"]
  verify                = local.linkerd-viz["verify"]
  values = compact([
    local.values_linkerd-viz,
    local.linkerd-viz["extra_values"],
    local.linkerd-viz.ha ? local.values_linkerd-viz_ha : null
  ])
  namespace = local.linkerd-viz["create_ns"] ? kubernetes_namespace.linkerd-viz[0].metadata[0].name[count.index] : local.linkerd-viz["namespace"]
}

resource "kubernetes_network_policy" "linkerd-viz_default_deny" {
  count = local.linkerd-viz["create_ns"] && local.linkerd-viz["enabled"] && local.linkerd-viz["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.linkerd-viz[0].metadata[0].name[count.index]}-default-deny"
    namespace = kubernetes_namespace.linkerd-viz[0].metadata[0].name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "linkerd-viz_allow_namespace" {
  count = local.linkerd-viz["create_ns"] && local.linkerd-viz["enabled"] && local.linkerd-viz["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.linkerd-viz[0].metadata[0].name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.linkerd-viz[0].metadata[0].name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.linkerd-viz[0].metadata[0].name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
