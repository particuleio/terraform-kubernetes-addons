locals {

  external-dns = { for k, v in var.external-dns : k => merge(
    local.helm_defaults,
    {
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "external-dns")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "external-dns")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "external-dns")].version
      project_id             = "default-0"
      name                   = k
      namespace              = k
      service_account_name   = "external-dns"
      enable_monitoring      = false
      enabled                = false
      managed_zones          = []
      create_iam_resources   = true
      iam_policy_override    = null
      default_network_policy = true
      name_prefix            = "${var.cluster-name}"
    },
    v,
  ) }

  values_external-dns = { for k, v in local.external-dns : k => merge(
    {
      values = <<-VALUES
        provider: google
        txtPrefix: "ext-dns-"
        txtOwnerId: ${var.cluster-name}
        logFormat: json
        policy: sync
        serviceAccount:
          name: ${v.service_account_name}
          annotations:
            iam.gke.io/gcp-service-account: '${module.external_dns_workload_identity[k].gcp_service_account_email}'
        serviceMonitor:
          enabled: ${v.enable_monitoring}
        priorityClassName: ${local.priority-class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
        VALUES
    },
    v,
  ) if v.enabled }

  managed_zones_by_instance = flatten([
    for k, v in local.external-dns : [
      for idx, zone in lookup(v, "managed_zones", []) : {
        zone_name  = zone
        instance   = k
        project_id = v.project_id
      }
  ] if v.enabled && v.create_iam_resources])
}

# This module will create a Google Service account and configure the right permissions
# to be allowed to use the workload identity on GKE.
module "external_dns_workload_identity" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version = "~> 27.0.0"

  for_each = { for k, v in local.external-dns : k => v if v.enabled && v.create_iam_resources }

  name                = each.value.service_account_name
  namespace           = each.value.namespace
  project_id          = each.value.project_id
  roles               = ["roles/dns.reader"]
  use_existing_k8s_sa = true
  annotate_k8s_sa     = false
}

# This module will configure the required IAM permissions for external-dns service account
# to deal with Cloud DNS. The IAM permissions will be set at the resource level (DNS zone) and not at the project
# level.
resource "google_dns_managed_zone_iam_member" "external_dns_cloud_dns_iam_permissions" {
  for_each     = { for idx, item in local.managed_zones_by_instance : "${item.instance}-${item.zone_name}" => item }
  project      = each.value.project_id
  managed_zone = each.value.zone_name
  role         = "roles/dns.admin"
  member       = "serviceAccount:${module.external_dns_workload_identity[each.value.instance].gcp_service_account_email}"
}


# This resource will create a dedicated namespace for each external-dns instance.
resource "kubernetes_namespace" "external-dns" {
  for_each = { for k, v in local.external-dns : k => v if v.enabled }

  metadata {
    labels = {
      name = each.value.namespace
    }

    name = each.value.namespace
  }
}

# This resource will create a helm release for each external-dns instance.
resource "helm_release" "external-dns" {
  for_each              = { for k, v in local.external-dns : k => v if v.enabled }
  repository            = each.value.repository
  name                  = each.value.name
  chart                 = each.value.chart
  version               = each.value.chart_version
  timeout               = each.value.timeout
  force_update          = each.value.force_update
  recreate_pods         = each.value.recreate_pods
  wait                  = each.value.wait
  atomic                = each.value.atomic
  cleanup_on_fail       = each.value.cleanup_on_fail
  dependency_update     = each.value.dependency_update
  disable_crd_hooks     = each.value.disable_crd_hooks
  disable_webhooks      = each.value.disable_webhooks
  render_subchart_notes = each.value.render_subchart_notes
  replace               = each.value.replace
  reset_values          = each.value.reset_values
  reuse_values          = each.value.reuse_values
  skip_crds             = each.value.skip_crds
  verify                = each.value.verify
  values = [
    local.values_external-dns[each.key].values,
    each.value.extra_values
  ]
  namespace = kubernetes_namespace.external-dns[each.key].metadata.0.name
}

# This resource will create for each external-dns instance a network policy to deny all ingress traffic
# by default in the namespace.
resource "kubernetes_network_policy" "external-dns_default_deny" {
  for_each = { for k, v in local.external-dns : k => v if v.enabled && v.default_network_policy }

  metadata {
    name      = "${kubernetes_namespace.external-dns[each.key].metadata.0.name}-default-deny"
    namespace = kubernetes_namespace.external-dns[each.key].metadata.0.name
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

# This resource will create for each external-dns instance a network policy to allow the
# workloads to communicate each other inside the external-dns namespace.
resource "kubernetes_network_policy" "external-dns_allow_namespace" {
  for_each = { for k, v in local.external-dns : k => v if v.enabled && v.default_network_policy }

  metadata {
    name      = "${kubernetes_namespace.external-dns[each.key].metadata.0.name}-allow-namespace"
    namespace = kubernetes_namespace.external-dns[each.key].metadata.0.name
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.external-dns[each.key].metadata.0.name
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

# This resource will create for each external-dns instance a network policy to allow the
# monitoring agent to collect metrics.
resource "kubernetes_network_policy" "external-dns_allow_monitoring" {
  for_each = { for k, v in local.external-dns : k => v if v.enabled && v.default_network_policy }

  metadata {
    name      = "${kubernetes_namespace.external-dns[each.key].metadata.0.name}-allow-monitoring"
    namespace = kubernetes_namespace.external-dns[each.key].metadata.0.name
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
            "${local.labels_prefix}/component" = "monitoring"
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
