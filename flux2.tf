locals {

  # GITHUB_TOKEN should be set for Github provider to work
  # GITHUB_ORGANIZATION should be set if deploying in another ORG and not your
  # github user

  flux2 = merge(
    {
      enabled                  = false
      create_ns                = true
      namespace                = "flux-system"
      path                     = "gitops/clusters/${var.cluster-name}"
      version                  = "v2.0.0-rc.5"
      create_github_repository = false
      repository               = "gitops"
      repository_visibility    = "public"
      branch                   = "main"
      components_extra         = ["image-reflector-controller", "image-automation-controller"]
      read_only                = false
      default_network_policy   = true
    },
    var.flux2
  )
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

resource "tls_private_key" "identity" {
  count       = local.flux2["enabled"] ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P521"
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

resource "github_repository_deploy_key" "main" {
  count      = local.flux2["enabled"] ? 1 : 0
  title      = "flux-${local.flux2["create_github_repository"] ? github_repository.main[0].name : local.flux2["repository"]}-${local.flux2["branch"]}"
  repository = local.flux2["create_github_repository"] ? github_repository.main[0].name : data.github_repository.main[0].name
  key        = tls_private_key.identity[0].public_key_openssh
  read_only  = local.flux2["read_only"]
}

resource "flux_bootstrap_git" "flux" {
  count = local.flux2["enabled"] ? 1 : 0

  depends_on = [
    github_repository_deploy_key.main,
    kubernetes_namespace.flux2
  ]

  path                    = local.flux2["path"]
  version                 = local.flux2["version"]
  namespace               = local.flux2["namespace"]
  cluster_domain          = try(local.flux2["cluster_domain"], null)
  components              = try(local.flux2["components"], null)
  components_extra        = try(local.flux2["components_extra"], null)
  disable_secret_creation = try(local.flux2["disable_secret_creation"], null)
  image_pull_secret       = try(local.flux2["image_pull_secrets"], null)
  interval                = try(local.flux2["interval"], null)
  kustomization_override  = try(local.flux2["kustomization_override"], null)
  log_level               = try(local.flux2["log_level"], null)
  network_policy          = try(local.flux2["network_policy"], null)
  recurse_submodules      = try(local.flux2["recurse_submodules"], null)
  registry                = try(local.flux2["registry"], null)
  secret_name             = try(local.flux2["secret_name"], null)
  toleration_keys         = try(local.flux2["toleration_keys"], null)
  watch_all_namespaces    = try(local.flux2["watch_all_namespaces"], null)

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
