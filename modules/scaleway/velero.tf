locals {
  velero = merge(
    local.helm_defaults,
    {
      name                      = local.helm_dependencies[index(local.helm_dependencies.*.name, "velero")].name
      chart                     = local.helm_dependencies[index(local.helm_dependencies.*.name, "velero")].name
      repository                = local.helm_dependencies[index(local.helm_dependencies.*.name, "velero")].repository
      chart_version             = local.helm_dependencies[index(local.helm_dependencies.*.name, "velero")].version
      namespace                 = "velero"
      service_account_name      = "velero"
      enabled                   = false
      create_bucket             = true
      bucket                    = "${var.cluster-name}-velero"
      bucket_force_destroy      = false
      default_network_policy    = true
      name_prefix               = "${var.cluster-name}-velero"
      secret_name               = "velero-scaleway-credentials"
    },
    var.velero
  )

  values_velero = <<VALUES
metrics:
  serviceMonitor:
    enabled: ${local.kube-prometheus-stack.enabled || local.victoria-metrics-k8s-stack.enable}
configuration:
  namespace: ${local.velero.namespace}
  features: EnableCSI
  backupStorageLocation:
    - name: aws
      provider: aws
      bucket: ${local.velero.bucket}
      default: true
serviceAccount:
  server:
    name: ${local.velero.service_account_name}
priorityClassName: ${local.priority-class-ds.create ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}
credentials:
  useSecret: true
  existingSecret: ${local.velero.secret_name}
initContainers:
   - name: velero-plugin-for-aws
     image: velero/velero-plugin-for-aws:v1.9.2
     imagePullPolicy: IfNotPresent
     volumeMounts:
       - mountPath: /target
         name: plugins
VALUES
}

resource "scaleway_object_bucket" "velero_bucket" {
  count = local.velero.enabled && local.velero.create_bucket  ? 1 : 0
  name  = local.velero.bucket

  versioning {
    enabled = true
  }

  force_destroy = local.velero.bucket_force_destroy

  tags = local.tags
}

resource "scaleway_object_bucket_acl" "velero_bucket_acl" {
  bucket = scaleway_object_bucket.velero_bucket.id
  acl = "private"
}

resource "kubernetes_namespace" "velero" {
  count = local.velero.enabled ? 1 : 0

  metadata {
    labels = {
      name = local.velero.namespace
    }

    name = local.velero.namespace
  }
}

resource "helm_release" "velero" {
  count                 = local.velero.enabled ? 1 : 0
  repository            = local.velero.repository
  name                  = local.velero.name
  chart                 = local.velero.chart
  version               = local.velero.chart_version
  timeout               = local.velero.timeout
  force_update          = local.velero.force_update
  recreate_pods         = local.velero.recreate_pods
  wait                  = local.velero.wait
  atomic                = local.velero.atomic
  cleanup_on_fail       = local.velero.cleanup_on_fail
  dependency_update     = local.velero.dependency_update
  disable_crd_hooks     = local.velero.disable_crd_hooks
  disable_webhooks      = local.velero.disable_webhooks
  render_subchart_notes = local.velero.render_subchart_notes
  replace               = local.velero.replace
  reset_values          = local.velero.reset_values
  reuse_values          = local.velero.reuse_values
  skip_crds             = local.velero.skip_crds
  verify                = local.velero.verify
  values = compact([
    local.values_velero,
    local.velero.extra_values
  ])
  namespace = kubernetes_namespace.velero.*.metadata.0.name[count.index]

  depends_on = [
    kubectl_manifest.prometheus-operator_crds
  ]
}

resource "kubernetes_network_policy" "velero_default_deny" {
  count = local.velero.enabled && local.velero.default_network_policy ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.velero.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.velero.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "velero_allow_namespace" {
  count = local.velero.enabled && local.velero.default_network_policy ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.velero.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.velero.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.velero.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "velero_allow_monitoring" {
  count = local.velero.enabled && local.velero.default_network_policy ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.velero.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.velero.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      ports {
        port     = "8085"
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
