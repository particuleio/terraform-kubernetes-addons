locals {
  aws_secret_sidecar_injector = merge(
    local.helm_defaults,
    {
      name                   = "aws-secret-sidecar-injector"
      namespace              = "aws-secret-sidecar-injector"
      chart                  = "secret-inject"
      repository             = "https://aws-samples.github.io/aws-secret-sidecar-injector/"
      enabled                = false
      chart_version          = "0.1.3"
      version                = "1"
      default_network_policy = true
      secret_scope           = ["*"]
    },
    var.aws_secret_sidecar_injector
  )

  values_aws_secret_sidecar_injector = <<VALUES
VALUES
}

resource "kubernetes_namespace" "aws_secret_sidecar_injector" {
  count = local.aws_secret_sidecar_injector["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.aws_secret_sidecar_injector["namespace"]
    }

    name = local.aws_secret_sidecar_injector["namespace"]
  }
}

resource "helm_release" "aws_secret_sidecar_injector" {
  count                 = local.aws_secret_sidecar_injector["enabled"] ? 1 : 0
  repository            = local.aws_secret_sidecar_injector["repository"]
  name                  = local.aws_secret_sidecar_injector["name"]
  chart                 = local.aws_secret_sidecar_injector["chart"]
  version               = local.aws_secret_sidecar_injector["chart_version"]
  timeout               = local.aws_secret_sidecar_injector["timeout"]
  force_update          = local.aws_secret_sidecar_injector["force_update"]
  recreate_pods         = local.aws_secret_sidecar_injector["recreate_pods"]
  wait                  = local.aws_secret_sidecar_injector["wait"]
  atomic                = local.aws_secret_sidecar_injector["atomic"]
  cleanup_on_fail       = local.aws_secret_sidecar_injector["cleanup_on_fail"]
  dependency_update     = local.aws_secret_sidecar_injector["dependency_update"]
  disable_crd_hooks     = local.aws_secret_sidecar_injector["disable_crd_hooks"]
  disable_webhooks      = local.aws_secret_sidecar_injector["disable_webhooks"]
  render_subchart_notes = local.aws_secret_sidecar_injector["render_subchart_notes"]
  replace               = local.aws_secret_sidecar_injector["replace"]
  reset_values          = local.aws_secret_sidecar_injector["reset_values"]
  reuse_values          = local.aws_secret_sidecar_injector["reuse_values"]
  skip_crds             = local.aws_secret_sidecar_injector["skip_crds"]
  verify                = local.aws_secret_sidecar_injector["verify"]
  values = [
    local.values_aws_secret_sidecar_injector,
    local.aws_secret_sidecar_injector["extra_values"]
  ]
  namespace = local.aws_secret_sidecar_injector["namespace"]

  depends_on = [
    helm_release.prometheus_operator
  ]
}

resource "kubernetes_network_policy" "aws_secret_sidecar_injector_default_deny" {
  count = local.aws_secret_sidecar_injector["enabled"] && local.aws_secret_sidecar_injector["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.aws_secret_sidecar_injector.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.aws_secret_sidecar_injector.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "aws_secret_sidecar_injector_allow_namespace" {
  count = local.aws_secret_sidecar_injector["enabled"] && local.aws_secret_sidecar_injector["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.aws_secret_sidecar_injector.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.aws_secret_sidecar_injector.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.aws_secret_sidecar_injector.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
