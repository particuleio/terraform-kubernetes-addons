locals {
  cert-manager = merge(
    local.helm_defaults,
    {
      name                      = local.helm_dependencies[index(local.helm_dependencies.*.name, "cert-manager")].name
      chart                     = local.helm_dependencies[index(local.helm_dependencies.*.name, "cert-manager")].name
      repository                = local.helm_dependencies[index(local.helm_dependencies.*.name, "cert-manager")].repository
      chart_version             = local.helm_dependencies[index(local.helm_dependencies.*.name, "cert-manager")].version
      namespace                 = "cert-manager"
      service_account_name      = "cert-manager"
      project_id                = "default-0"
      create_iam_resources      = true
      enable_monitoring         = false
      enabled                   = false
      iam_policy_override       = null
      default_network_policy    = true
      managed_zone              = "default"
      acme_email                = "contact@acme.com"
      acme_http01_enabled       = true
      acme_http01_ingress_class = "nginx"
      acme_dns01_enabled        = true
      acme_dns01_provider       = "clouddns"
      acme_dns01_provider_clouddns = {
        project_id    = "default-0"
        dns_zone_name = "default"
      }
      acme_dns01_provider_route53 = {
        aws_region = "eu-west1"
      }
      allowed_cidrs = ["0.0.0.0/0"]
      csi_driver    = false
      name_prefix   = "${var.cluster-name}-cert-manager"
    },
    var.cert-manager
  )


  values_cert-manager = <<VALUES
global:
  priorityClassName: ${local.priority-class.create ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
serviceAccount:
  name: ${local.cert-manager.service_account_name}
  annotations:
    iam.gke.io/gcp-service-account: "${local.cert-manager.create_iam_resources && local.cert-manager.enabled ? module.cert_manager_workload_identity[0].gcp_service_account_email : ""}"
prometheus:
  servicemonitor:
    enabled: ${local.cert-manager.enable_monitoring}
    honorLabels: true
securityContext:
  fsGroup: 1001
installCRDs: true
VALUES
}

# This module will create a Google Service account and configure the right permissions
# to be allowed to use the workload identity on GKE.
module "cert_manager_workload_identity" {
  count               = local.cert-manager.create_iam_resources && local.cert-manager.enabled ? 1 : 0
  source              = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version             = "~> 27.0.0"
  name                = local.cert-manager.service_account_name
  namespace           = local.cert-manager.namespace
  project_id          = local.cert-manager.project_id
  roles               = []
  use_existing_k8s_sa = true
  annotate_k8s_sa     = false
}

# This resource will configure the required IAM permissions for the cert-manager service account
# to deal with Cloud DNS. The IAM permissions will be set at the resource level (DNS zone) and not at the project
# level.
resource "google_dns_managed_zone_iam_member" "cert_manager_cloud_dns_iam_permissions" {
  count        = local.cert-manager.create_iam_resources && local.cert-manager.enabled ? 1 : 0
  project      = local.cert-manager.project_id
  managed_zone = local.cert-manager.managed_zone
  role         = "roles/dns.admin"
  member       = "serviceAccount:${module.cert_manager_workload_identity.0.gcp_service_account_email}"
}

# This resource will create a dedicated Kubernetes namespace for cert-manager.
resource "kubernetes_namespace" "cert-manager" {
  count = local.cert-manager.enabled ? 1 : 0

  metadata {
    annotations = {
      "certmanager.k8s.io/disable-validation" = "true"
    }

    labels = {
      name = local.cert-manager["namespace"]
    }

    name = local.cert-manager["namespace"]
  }
}

# This resource will deploy a Flux HelmRelease on the cluster to deploy
# cert-manager official helm chart.
resource "helm_release" "cert-manager" {
  count                 = local.cert-manager.enabled ? 1 : 0
  repository            = local.cert-manager.repository
  name                  = local.cert-manager.name
  chart                 = local.cert-manager.chart
  version               = local.cert-manager.chart_version
  timeout               = local.cert-manager.timeout
  force_update          = local.cert-manager.force_update
  recreate_pods         = local.cert-manager.recreate_pods
  wait                  = local.cert-manager.wait
  atomic                = local.cert-manager.atomic
  cleanup_on_fail       = local.cert-manager.cleanup_on_fail
  dependency_update     = local.cert-manager.dependency_update
  disable_crd_hooks     = local.cert-manager.disable_crd_hooks
  disable_webhooks      = local.cert-manager.disable_webhooks
  render_subchart_notes = local.cert-manager.render_subchart_notes
  replace               = local.cert-manager.replace
  reset_values          = local.cert-manager.reset_values
  reuse_values          = local.cert-manager.reuse_values
  skip_crds             = local.cert-manager.skip_crds
  verify                = local.cert-manager.verify
  values = [
    local.values_cert-manager,
    local.cert-manager["extra_values"]
  ]
  namespace = kubernetes_namespace.cert-manager.*.metadata.0.name[count.index]
}

# This resource will render our jinja template for our cluster issuers.
data "jinja_template" "cert-manager_cluster_issuers" {
  template = "./templates/cert-manager-cluster-issuers.yaml.j2"
  context {
    type = "yaml"
    data = yamlencode({
      acme_email                   = local.cert-manager.acme_email
      acme_http01_enabled          = local.cert-manager.acme_http01_enabled
      acme_http01_ingress_class    = local.cert-manager.acme_http01_ingress_class
      acme_dns01_enabled           = local.cert-manager.acme_dns01_enabled
      acme_dns01_provider          = local.cert-manager.acme_dns01_provider
      acme_dns01_provider_clouddns = local.cert-manager.acme_dns01_provider_clouddns
      acme_dns01_provider_route53  = local.cert-manager.acme_dns01_provider_route53
    })
  }
  strict_undefined = false
}

# This resource will split our rendered cluster issuers manifest into a list of individual document.
data "kubectl_file_documents" "cert-manager_cluster_issuers" {
  content = data.jinja_template.cert-manager_cluster_issuers.result
}

# This resource is there to wait for cert-manager to be deployed before creating certificate issuers.
resource "time_sleep" "cert-manager_sleep" {
  count           = local.cert-manager.enabled && (local.cert-manager.acme_http01_enabled || local.cert-manager.acme_dns01_enabled) ? 1 : 0
  depends_on      = [helm_release.cert-manager]
  create_duration = "120s"
}

# This ressource will deploy the certificate issuers on the clusters.
resource "kubectl_manifest" "cert-manager_cluster_issuers" {
  count     = local.cert-manager.enabled && (local.cert-manager.acme_http01_enabled || local.cert-manager.acme_dns01_enabled) ? length(data.kubectl_file_documents.cert-manager_cluster_issuers.documents) : 0
  yaml_body = element(data.kubectl_file_documents.cert-manager_cluster_issuers.documents, count.index)
  depends_on = [
    helm_release.cert-manager,
    kubernetes_namespace.cert-manager,
    time_sleep.cert-manager_sleep
  ]
}

# This resource will create a network policy which deny all ingress traffic from cert-manager
# namespace.
resource "kubernetes_network_policy" "cert-manager_default_deny" {
  count = local.cert-manager.enabled && local.cert-manager.default_network_policy ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.cert-manager.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.cert-manager.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

# This resource will create a network policy which allows the workloads in cert-manager
# namespace to communicate.
resource "kubernetes_network_policy" "cert-manager_allow_namespace" {
  count = local.cert-manager.enabled && local.cert-manager.default_network_policy ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.cert-manager.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.cert-manager.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.cert-manager.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

# This resource will create a network policy to allow monitoring agent to collect
# metrics.
resource "kubernetes_network_policy" "cert-manager_allow_monitoring" {
  count = local.cert-manager.enabled && local.cert-manager.default_network_policy ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.cert-manager.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.cert-manager.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      ports {
        port     = "9402"
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

# This resource will create a network policy which will allow control plane to reach
# cert-manager webhook on port 10250.
resource "kubernetes_network_policy" "cert-manager_allow_control_plane" {
  count = local.cert-manager.enabled && local.cert-manager.default_network_policy ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.cert-manager.*.metadata.0.name[count.index]}-allow-control-plane"
    namespace = kubernetes_namespace.cert-manager.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "app.kubernetes.io/name"
        operator = "In"
        values   = ["webhook"]
      }
    }

    ingress {
      ports {
        port     = "10250"
        protocol = "TCP"
      }

      dynamic "from" {
        for_each = local.cert-manager.allowed_cidrs
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
