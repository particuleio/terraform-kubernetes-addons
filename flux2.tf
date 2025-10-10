locals {

  flux-operator = merge(
    local.helm_defaults,
    {
      name                   = "flux-operator"
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator")].name
      repository             = ""
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator")].version
      enabled                = false
      create_ns              = true
      namespace              = "flux-system"
      extra_ns_labels        = {}
      extra_ns_annotations   = {}
      default_network_policy = true
    },
    var.flux-operator
  )

  values_flux-operator = <<VALUES
    serviceMonitor:
      enabled: ${local.kube-prometheus-stack["enabled"] || local.victoria-metrics-k8s-stack["enabled"]}
  VALUES

  flux2 = merge(
    local.helm_defaults,
    {
      name                       = "flux"
      chart                      = local.helm_dependencies[index(local.helm_dependencies.*.name, "oci://ghcr.io/controlplaneio-fluxcd/charts/flux-instance")].name
      repository                 = ""
      chart_version              = local.helm_dependencies[index(local.helm_dependencies.*.name, "oci://ghcr.io/controlplaneio-fluxcd/charts/flux-instance")].version
      enabled                    = false
      create_ns                  = true
      namespace                  = "flux-system"
      version                    = "v2.6.1"
      cluster_type               = "kubernetes"
      cluster_size               = "medium"
      git_path                   = "gitops/clusters/${var.cluster-name}"
      git_ref                    = "refs/heads/main"
      git_token                  = ""
      github_app_id              = ""
      github_app_installation_id = ""
      github_app_pem             = ""
      components                 = ["source-controller", "kustomize-controller", "helm-controller", "notification-controller", "image-reflector-controller", "image-automation-controller"]
      create_github_repository   = false
      repository                 = "gitops"
      repository_visibility      = "public"
      default_network_policy     = true
    },
    var.flux2
  )

  values_flux2 = <<VALUES
    instance:
      components: ${local.flux2["components"]}
      distribution:
        version: ${local.flux2["flux_version"]}
      cluster:
        type: ${local.flux2["cluster_type"]}
        size: ${local.flux2["cluster_size"]}
      sync:
        kind: GitRepository
        url: ${local.flux2["create_github_repository"]} ? ${github_repository.main[0].name} : ${data.github_repository.main[0].name}
        path: ${local.flux2["git_path"]}
        ref: ${local.flux2["git_ref"]}
        provider: ${local.flux2["github_app_id"] != "" ? "github" : "generic"}
        pullSecret: ${local.flux2["git_token"] != "" || local.flux2["github_app_id"] != "" ? "flux-system" : ""}
    healthcheck:
      enabled: true
 VALUES
}

resource "kubernetes_namespace" "flux2" {
  count = local.flux2["enabled"] && local.flux2["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name = local.flux2["namespace"]
    }

    name = local.flux2["namespace"]
  }
  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels,
    ]
  }
}

// Create a Kubernetes secret with the Git credentials
// if a GitHub/GitLab token or GitHub App is provided.

resource "kubernetes_secret" "git_auth" {
  count      = local.flux2["git_token"] != "" || local.flux2["github_app_id"] != "" ? 1 : 0
  depends_on = [kubernetes_namespace.flux2]

  metadata {
    name      = "flux-system"
    namespace = local.flux2["namespace"]
  }

  data = {
    username                = local.flux2["git_token"] != "" ? "git" : null
    password                = local.flux2["git_token"] != "" ? local.flux2["git_token"] : null
    githubAppID             = local.flux2["github_app_id"] != "" ? local.flux2["github_app_id"] : null
    githubAppInstallationID = local.flux2["github_app_installation_id"] != "" ? local.flux2["github_app_installation_id"] : null
    githubAppPrivateKey     = local.flux2["github_app_pem"] != "" ? local.flux2["github_app_pem"] : null
  }

  type = "Opaque"
}

// Install the Flux Operator.
resource "helm_release" "flux_operator" {
  depends_on = [kubernetes_namespace.flux2]

  count                 = local.flux-operator["enabled"] ? 1 : 0
  repository            = local.flux-operator["repository"]
  name                  = local.flux-operator["name"]
  chart                 = local.flux-operator["chart"]
  version               = local.flux-operator["chart_version"]
  timeout               = local.flux-operator["timeout"]
  force_update          = local.flux-operator["force_update"]
  recreate_pods         = local.flux-operator["recreate_pods"]
  wait                  = local.flux-operator["wait"]
  atomic                = local.flux-operator["atomic"]
  cleanup_on_fail       = local.flux-operator["cleanup_on_fail"]
  dependency_update     = local.flux-operator["dependency_update"]
  disable_crd_hooks     = local.flux-operator["disable_crd_hooks"]
  disable_webhooks      = local.flux-operator["disable_webhooks"]
  render_subchart_notes = local.flux-operator["render_subchart_notes"]
  replace               = local.flux-operator["replace"]
  reset_values          = local.flux-operator["reset_values"]
  reuse_values          = local.flux-operator["reuse_values"]
  skip_crds             = local.flux-operator["skip_crds"]
  verify                = local.flux-operator["verify"]
  values = [
    local.values_flux-operator,
    local.flux-operator["extra_values"],
  ]
  namespace = kubernetes_namespace.flux2.*.metadata.0.name[count.index]
}

resource "helm_release" "flux2" {
  depends_on = [helm_release.flux_operator]

  count                 = local.flux2["enabled"] ? 1 : 0
  repository            = local.flux2["repository"]
  name                  = local.flux2["name"]
  chart                 = local.flux2["chart"]
  version               = local.flux2["chart_version"]
  timeout               = local.flux2["timeout"]
  force_update          = local.flux2["force_update"]
  recreate_pods         = local.flux2["recreate_pods"]
  wait                  = local.flux2["wait"]
  atomic                = local.flux2["atomic"]
  cleanup_on_fail       = local.flux2["cleanup_on_fail"]
  dependency_update     = local.flux2["dependency_update"]
  disable_crd_hooks     = local.flux2["disable_crd_hooks"]
  disable_webhooks      = local.flux2["disable_webhooks"]
  render_subchart_notes = local.flux2["render_subchart_notes"]
  replace               = local.flux2["replace"]
  reset_values          = local.flux2["reset_values"]
  reuse_values          = local.flux2["reuse_values"]
  skip_crds             = local.flux2["skip_crds"]
  verify                = local.flux2["verify"]
  values = [
    local.values_flux2,
    local.flux2["extra_values"],
  ]
  namespace = kubernetes_namespace.flux2.*.metadata.0.name[count.index]
}

data "github_repository" "main" {
  count = local.flux2["enabled"] && !local.flux2["create_github_repository"] ? 1 : 0
  name  = local.flux2["repository"]
}

resource "github_repository" "main" {
  count      = local.flux2["enabled"] && local.flux2["create_github_repository"] ? 1 : 0
  name       = local.flux2["repository"]
  visibility = local.flux2["repository_visibility"]
  auto_init  = true
}

resource "github_branch_default" "main" {
  count      = local.flux2["enabled"] && local.flux2["create_github_repository"] ? 1 : 0
  repository = local.flux2["create_github_repository"] ? github_repository.main[0].name : data.github_repository.main[0].name
  branch     = local.flux2["branch"]
}

resource "kubernetes_network_policy" "flux2_allow_monitoring" {
  count = local.flux2["enabled"] && local.flux2["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${local.flux2["create_ns"] ? kubernetes_namespace.flux2.*.metadata.0.name[count.index] : local.flux2["namespace"]}-allow-monitoring"
    namespace = local.flux2["create_ns"] ? kubernetes_namespace.flux2.*.metadata.0.name[count.index] : local.flux2["namespace"]
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
            "${local.labels_prefix}/component" = "monitoring"
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "flux2_allow_namespace" {
  count = local.flux2["enabled"] && local.flux2["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${local.flux2["create_ns"] ? kubernetes_namespace.flux2.*.metadata.0.name[count.index] : local.flux2["namespace"]}-allow-namespace"
    namespace = local.flux2["create_ns"] ? kubernetes_namespace.flux2.*.metadata.0.name[count.index] : local.flux2["namespace"]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = local.flux2["create_ns"] ? kubernetes_namespace.flux2.*.metadata.0.name[count.index] : local.flux2["namespace"]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
