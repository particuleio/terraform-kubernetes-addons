locals {
  linkerd-viz = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "linkerd-viz")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "linkerd-viz")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "linkerd-viz")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "linkerd-viz")].version
      namespace              = "linkerd-viz"
      create_ns              = true
      enabled                = local.linkerd.enabled
      default_network_policy = true
      allowed_cidrs          = ["0.0.0.0/0"]
      ha                     = true
    },
    var.linkerd-viz
  )

  values_linkerd-viz = <<VALUES
    linkerdNamespace: ${local.linkerd["namespace"]}
    VALUES

  values_linkerd-viz_ha = <<VALUES
    #
    # The below is taken from: https://github.com/linkerd/linkerd2/blob/main/viz/charts/linkerd-viz/values-ha.yaml
    #

    # This values.yaml file contains the values needed to enable HA mode.
    # Usage:
    #   helm install -f values.yaml -f values-ha.yaml

    enablePodAntiAffinity: true

    # nodeAffinity:

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

  linkerd-viz_manifests = {
    prometheus-servicemonitor         = <<-VALUES
      apiVersion: monitoring.coreos.com/v1
      kind: ServiceMonitor
      metadata:
        labels:
          k8s-app: linkerd-prometheus
          release: monitoring
        name: linkerd-federate
        namespace: ${local.linkerd-viz.namespace}
      spec:
        endpoints:
        - interval: 30s
          scrapeTimeout: 30s
          params:
            match[]:
            - '{job="linkerd-proxy"}'
            - '{job="linkerd-controller"}'
          path: /federate
          port: admin-http
          honorLabels: true
          relabelings:
          - action: keep
            regex: '^prometheus$'
            sourceLabels:
            - '__meta_kubernetes_pod_container_name'
        jobLabel: app
        namespaceSelector:
          matchNames:
          - ${local.linkerd-viz.namespace}
        selector:
          matchLabels:
            component: prometheus
      VALUES
    allow-prometheus-admin-federation = <<-VALUES
      apiVersion: policy.linkerd.io/v1beta1
      kind: ServerAuthorization
      metadata:
        namespace: ${local.linkerd-viz.namespace}
        name: prometheus-admin-federation
      spec:
        server:
          name: prometheus-admin
        client:
          unauthenticated: true
      VALUES
  }
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

resource "kubectl_manifest" "linkerd-viz" {
  for_each  = local.linkerd-viz.enabled && local.kube-prometheus-stack.enabled ? local.linkerd-viz_manifests : {}
  yaml_body = each.value
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
  namespace = local.linkerd-viz["create_ns"] ? kubernetes_namespace.linkerd-viz.*.metadata.0.name[count.index] : local.linkerd-viz["namespace"]

  depends_on = [helm_release.linkerd-control-plane]
}

resource "kubernetes_network_policy" "linkerd-viz_default_deny" {
  count = local.linkerd-viz["create_ns"] && local.linkerd-viz["enabled"] && local.linkerd-viz["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.linkerd-viz.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.linkerd-viz.*.metadata.0.name[count.index]
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
    name      = "${kubernetes_namespace.linkerd-viz.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.linkerd-viz.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.linkerd-viz.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "linkerd-viz_allow_control_plane" {
  count = local.linkerd-viz["enabled"] && local.linkerd-viz["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.linkerd-viz.*.metadata.0.name[count.index]}-allow-control-plane"
    namespace = kubernetes_namespace.linkerd-viz.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      ports {
        port     = "8089"
        protocol = "TCP"
      }

      dynamic "from" {
        for_each = local.linkerd-viz["allowed_cidrs"]
        content {
          ip_block {
            cidr = from.value
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "linkerd-viz_allow_monitoring" {
  count = local.linkerd-viz["enabled"] && local.linkerd-viz["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.linkerd-viz.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.linkerd-viz.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "${local.labels_prefix}/component" = "monitoring"
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
