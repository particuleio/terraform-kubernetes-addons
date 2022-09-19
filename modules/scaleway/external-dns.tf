locals {

  external-dns = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "external-dns")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "external-dns")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "external-dns")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "external-dns")].version
      namespace              = "external-dns"
      service_account_name   = "external-dns"
      enabled                = false
      default_network_policy = true
      secret_name            = "scaleway-credentials"
    },
    var.external-dns
  )

  values_external-dns = <<-VALUES
    provider: scaleway
    txtPrefix: "ext-dns-"
    txtOwnerId: ${var.cluster-name}
    logFormat: json
    policy: sync
    logFormat: json
    serviceMonitor:
      enabled: ${local.kube-prometheus-stack["enabled"] || local.victoria-metrics-k8s-stack["enabled"]}
    priorityClassName: ${local.priority-class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
    env:
    - name: SCW_ACCESS_KEY
      valueFrom:
        secretKeyRef:
          name: ${local.external-dns["secret_name"]}
          key: SCW_ACCESS_KEY
    - name: SCW_SECRET_KEY
      valueFrom:
        secretKeyRef:
          name: ${local.external-dns["secret_name"]}
          key: SCW_SECRET_KEY
    - name: SCW_DEFAULT_ORGANIZATION_ID
      valueFrom:
        secretKeyRef:
          name: ${local.external-dns["secret_name"]}
          key: SCW_DEFAULT_ORGANIZATION_ID
    VALUES
}

resource "kubernetes_namespace" "external-dns" {
  count = local.external-dns["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.external-dns["namespace"]
    }

    name = local.external-dns["namespace"]
  }
}

resource "helm_release" "external-dns" {
  count                 = local.external-dns["enabled"] ? 1 : 0
  repository            = local.external-dns["repository"]
  name                  = local.external-dns["name"]
  chart                 = local.external-dns["chart"]
  version               = local.external-dns["chart_version"]
  timeout               = local.external-dns["timeout"]
  force_update          = local.external-dns["force_update"]
  recreate_pods         = local.external-dns["recreate_pods"]
  wait                  = local.external-dns["wait"]
  atomic                = local.external-dns["atomic"]
  cleanup_on_fail       = local.external-dns["cleanup_on_fail"]
  dependency_update     = local.external-dns["dependency_update"]
  disable_crd_hooks     = local.external-dns["disable_crd_hooks"]
  disable_webhooks      = local.external-dns["disable_webhooks"]
  render_subchart_notes = local.external-dns["render_subchart_notes"]
  replace               = local.external-dns["replace"]
  reset_values          = local.external-dns["reset_values"]
  reuse_values          = local.external-dns["reuse_values"]
  skip_crds             = local.external-dns["skip_crds"]
  verify                = local.external-dns["verify"]
  values = [
    local.values_external-dns,
    local.external-dns["extra_values"]
  ]
  namespace = kubernetes_namespace.external-dns.*.metadata.0.name[count.index]

  depends_on = [
    kubectl_manifest.prometheus-operator_crds
  ]
}

resource "kubernetes_secret" "external-dns_scaleway_credentials" {
  count = local.external-dns["enabled"] ? 1 : 0
  metadata {
    name      = local.external-dns["secret_name"]
    namespace = local.external-dns["namespace"]
  }
  data = {
    SCW_ACCESS_KEY              = local.scaleway["scw_access_key"]
    SCW_SECRET_KEY              = local.scaleway["scw_secret_key"]
    SCW_DEFAULT_ORGANIZATION_ID = local.scaleway["scw_default_organization_id"]
  }
}

resource "kubernetes_network_policy" "external-dns_default_deny" {
  count = local.external-dns["enabled"] && local.external-dns["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.external-dns.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.external-dns.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "external-dns_allow_namespace" {
  count = local.external-dns["enabled"] && local.external-dns["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.external-dns.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.external-dns.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.external-dns.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "external-dns_allow_monitoring" {
  count = local.external-dns["enabled"] && local.external-dns["default_network_policy"] && local.kube-prometheus-stack["enabled"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.external-dns.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.external-dns.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      ports {
        port     = "http"
        protocol = "TCP"
      }

      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.kube-prometheus-stack.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
