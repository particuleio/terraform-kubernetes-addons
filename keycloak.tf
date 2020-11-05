locals {
  keycloak = merge(
    local.helm_defaults,
    {
      name                   = "keycloak"
      namespace              = "keycloak"
      chart                  = "keycloak"
      repository             = "https://codecentric.github.io/helm-charts"
      prometheus_plugin      = true
      enabled                = false
      chart_version          = "9.0.6"
      version                = "11.0.2"
      default_network_policy = true
    },
    var.keycloak
  )

  values_keycloak = <<VALUES
image:
  tag: ${local.keycloak["version"]}
prometheus:
  operator:
    enabled: ${local.prometheus_operator["enabled"]}
    prometheusRules:
      enabled: ${local.prometheus_operator["enabled"]}
keycloak:
  priorityClassName: ${local.priority_class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
VALUES

  values_keycloak_prometheus = <<VALUES
extraInitContainers: |
  - name: extensions
    image: busybox
    imagePullPolicy: IfNotPresent
    command:
      - sh
    args:
      - -c
      - |
        echo "Copying extensions..."
        wget -O /deployments/keycloak-metrics-spi.jar https://github.com/aerogear/keycloak-metrics-spi/releases/download/2.0.1/keycloak-metrics-spi-2.0.1.jar
    volumeMounts:
      - name: deployments
        mountPath: /deployments

extraVolumeMounts: |
  - name: deployments
    mountPath: /opt/jboss/keycloak/standalone/deployments

extraVolumes: |
  - name: deployments
    emptyDir: {}
VALUES
}

resource "kubernetes_namespace" "keycloak" {
  count = local.keycloak["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.keycloak["namespace"]
    }

    name = local.keycloak["namespace"]
  }
}

resource "helm_release" "keycloak" {
  count                 = local.keycloak["enabled"] ? 1 : 0
  repository            = local.keycloak["repository"]
  name                  = local.keycloak["name"]
  chart                 = local.keycloak["chart"]
  version               = local.keycloak["chart_version"]
  timeout               = local.keycloak["timeout"]
  force_update          = local.keycloak["force_update"]
  recreate_pods         = local.keycloak["recreate_pods"]
  wait                  = local.keycloak["wait"]
  atomic                = local.keycloak["atomic"]
  cleanup_on_fail       = local.keycloak["cleanup_on_fail"]
  dependency_update     = local.keycloak["dependency_update"]
  disable_crd_hooks     = local.keycloak["disable_crd_hooks"]
  disable_webhooks      = local.keycloak["disable_webhooks"]
  render_subchart_notes = local.keycloak["render_subchart_notes"]
  replace               = local.keycloak["replace"]
  reset_values          = local.keycloak["reset_values"]
  reuse_values          = local.keycloak["reuse_values"]
  skip_crds             = local.keycloak["skip_crds"]
  verify                = local.keycloak["verify"]
  values = [
    local.values_keycloak,
    local.keycloak["prometheus_plugin"] ? local.values_keycloak_prometheus : "",
    local.keycloak["extra_values"]
  ]
  namespace = kubernetes_namespace.keycloak.*.metadata.0.name[count.index]

  depends_on = [
    helm_release.prometheus_operator
  ]
}

resource "kubernetes_network_policy" "keycloak_default_deny" {
  count = local.keycloak["enabled"] && local.keycloak["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.keycloak.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.keycloak.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "keycloak_allow_namespace" {
  count = local.keycloak["enabled"] && local.keycloak["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.keycloak.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.keycloak.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.keycloak.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "keycloak_allow_monitoring" {
  count = local.keycloak["enabled"] && local.keycloak["default_network_policy"] && local.prometheus_operator["enabled"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.keycloak.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.keycloak.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      ports {
        port     = "8080"
        protocol = "TCP"
      }

      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.prometheus_operator.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
