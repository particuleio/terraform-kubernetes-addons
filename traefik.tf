locals {

  traefik = merge(
    local.helm_defaults,
    {
      name                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "traefik")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "traefik")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "traefik")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "traefik")].version
      namespace              = "traefik"
      enabled                = false
      allowed_cidrs          = ["0.0.0.0/0"]
      default_network_policy = true
      manage_crds            = true
    },
    var.traefik
  )

  values_traefik = <<VALUES
VALUES
}


resource "kubernetes_namespace" "traefik" {
  count = local.traefik["enabled"] ? 1 : 0

  metadata {
    labels = {
      name                               = local.traefik["namespace"]
      "${local.labels_prefix}/component" = "ingress"
    }

    name = local.traefik["namespace"]
  }
}

resource "helm_release" "traefik" {
  count                 = local.traefik["enabled"] ? 1 : 0
  repository            = local.traefik["repository"]
  name                  = local.traefik["name"]
  chart                 = local.traefik["chart"]
  version               = local.traefik["chart_version"]
  timeout               = local.traefik["timeout"]
  force_update          = local.traefik["force_update"]
  recreate_pods         = local.traefik["recreate_pods"]
  wait                  = local.traefik["wait"]
  atomic                = local.traefik["atomic"]
  cleanup_on_fail       = local.traefik["cleanup_on_fail"]
  dependency_update     = local.traefik["dependency_update"]
  disable_crd_hooks     = local.traefik["disable_crd_hooks"]
  disable_webhooks      = local.traefik["disable_webhooks"]
  render_subchart_notes = local.traefik["render_subchart_notes"]
  replace               = local.traefik["replace"]
  reset_values          = local.traefik["reset_values"]
  reuse_values          = local.traefik["reuse_values"]
  skip_crds             = local.traefik["skip_crds"]
  verify                = local.traefik["verify"]
  values = compact([
    local.values_traefik,
    local.traefik["extra_values"],
  ])
  namespace = kubernetes_namespace.traefik.*.metadata.0.name[count.index]

  depends_on = [
    helm_release.kube-prometheus-stack,
  ]
}

resource "kubernetes_network_policy" "traefik_default_deny" {
  count = local.traefik["enabled"] && local.traefik["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.traefik.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.traefik.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "traefik_allow_namespace" {
  count = local.traefik["enabled"] && local.traefik["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.traefik.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.traefik.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.traefik.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "traefik_allow_monitoring" {
  count = local.traefik["enabled"] && local.traefik["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.traefik.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.traefik.*.metadata.0.name[count.index]
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

resource "kubernetes_network_policy" "traefik_allow_control_plane" {
  count = local.traefik["enabled"] && local.traefik["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.traefik.*.metadata.0.name[count.index]}-allow-control-plane"
    namespace = kubernetes_namespace.traefik.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "app"
        operator = "In"
        values   = ["${local.traefik["name"]}-operator"]
      }
    }

    ingress {
      ports {
        port     = "10250"
        protocol = "TCP"
      }

      dynamic "from" {
        for_each = local.traefik["allowed_cidrs"]
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
