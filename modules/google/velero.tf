locals {
  velero = merge(
    local.helm_defaults,
    {
      name                    = local.helm_dependencies[index(local.helm_dependencies.*.name, "velero")].name
      chart                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "velero")].name
      repository              = local.helm_dependencies[index(local.helm_dependencies.*.name, "velero")].repository
      chart_version           = local.helm_dependencies[index(local.helm_dependencies.*.name, "velero")].version
      namespace               = "velero"
      service_account_name    = "velero"
      enabled                 = false
      create_iam_account      = true
      iam_account_name        = "gke-${substr(var.cluster-name, 0, 18)}-velero"
      create_bucket           = true
      bucket                  = "${var.cluster-name}-velero"
      bucket_location         = "eu"
      bucket_force_destroy    = false
      bucket_versioning       = false
      allowed_cidrs           = ["0.0.0.0/0"]
      default_network_policy  = true
      kms_key_arn_access_list = []
      name_prefix             = "${var.cluster-name}-velero"
      snapshot_location       = "eu"
      create_snapshot_class   = true
    },
    var.velero
  )

  values_velero = <<VALUES
metrics:
  serviceMonitor:
    enabled: ${local.kube-prometheus-stack["enabled"] || local.victoria-metrics-k8s-stack["enabled"]}
configuration:
  namespace: ${local.velero["namespace"]}
  features: EnableCSI
  backupStorageLocation:
    - name: gcp
      provider: velero.io/gcp
      bucket: ${local.velero["bucket"]}
      default: true
      config:
        serviceAccount: ${local.velero["create_iam_account"] ? google_service_account.velero[0].email : "@@SETTHIS@@"}
  volumeSnapshotLocation:
    - name: gcp
      provider: velero.io/gcp
      snapshotLocation: ${local.velero["snapshot_location"]}
serviceAccount:
  server:
    name: ${local.velero["service_account_name"]}
    create: true
    annotations:
      iam.gke.io/gcp-service-account: ${local.velero["create_iam_account"] ? google_service_account.velero[0].email : ""}
priorityClassName: ${local.priority-class-ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}
credentials:
  useSecret: false
initContainers:
  - name: velero-plugin-for-gcp
    image: velero/velero-plugin-for-gcp:v1.10.1
    imagePullPolicy: IfNotPresent
    volumeMounts:
      - mountPath: /target
        name: plugins
VALUES

}

resource "google_project_iam_custom_role" "velero" {
  count       = (local.velero["enabled"] && local.velero["create_iam_account"]) ? 1 : 0
  role_id     = replace(local.velero["iam_account_name"], "-", "_")
  title       = "${var.cluster-name} - velero"
  description = "IAM role used by velero on ${var.cluster-name} to perform backup operations"
  permissions = [
    # https://github.com/vmware-tanzu/velero-plugin-for-gcp/blob/main/README.md#create-custom-role-with-permissions-for-the-velero-gsa
    "compute.disks.get",
    "compute.disks.create",
    "compute.disks.createSnapshot",
    "compute.projects.get",
    "compute.snapshots.get",
    "compute.snapshots.create",
    "compute.snapshots.useReadOnly",
    "compute.snapshots.delete",
    "compute.zones.get",
    # We set these privileges on the bucket directly
    # "storage.objects.create",
    # "storage.objects.delete",
    # "storage.objects.get",
    # "storage.objects.list",
    "iam.serviceAccounts.signBlob",
  ]
}

resource "google_service_account" "velero" {
  count        = (local.velero["enabled"] && local.velero["create_iam_account"]) ? 1 : 0
  account_id   = local.velero["iam_account_name"]
  display_name = "Velero on GKE ${var.cluster-name}"
  description  = "Service account for Velero on GKE cluster ${var.cluster-name}"
}

resource "google_project_iam_member" "velero" {
  count   = (local.velero["enabled"] && local.velero["create_iam_account"]) ? 1 : 0
  project = data.google_project.current.project_id
  role    = google_project_iam_custom_role.velero[0].id
  member  = google_service_account.velero[0].member
}

data "google_iam_policy" "velero" {
  binding {
    role = "roles/iam.workloadIdentityUser"

    members = [
      "serviceAccount:${data.google_project.current.project_id}.svc.id.goog[${local.velero["namespace"]}/${local.velero["service_account_name"]}]",
    ]
  }
}

resource "google_service_account_iam_policy" "admin-account-iam" {
  count              = (local.velero["enabled"] && local.velero["create_iam_account"]) ? 1 : 0
  service_account_id = google_service_account.velero[0].name
  policy_data        = data.google_iam_policy.velero.policy_data
}

module "velero_bucket" {
  count  = (local.velero["enabled"] && local.velero["create_bucket"]) ? 1 : 0
  source = "github.com/terraform-google-modules/terraform-google-cloud-storage//modules/simple_bucket?ref=v7.0.0"

  name       = local.velero["name_prefix"]
  project_id = data.google_project.current.project_id

  versioning = local.velero["bucket_versioning"]
  location   = local.velero["bucket_location"]

  force_destroy = local.velero["bucket_force_destroy"]

  iam_members = [
    {
      role   = "roles/storage.objectUser"
      member = "serviceAccount:${local.velero["iam_account_name"]}@${data.google_project.current.project_id}.iam.gserviceaccount.com" # This should be google_service_account.velero[0].member, but it's included in a loop so we have to determine it before apply
    }
  ]
  depends_on = [google_service_account.velero]
}

resource "kubernetes_namespace" "velero" {
  count = local.velero["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.velero["namespace"]
    }

    name = local.velero["namespace"]
  }
}

resource "helm_release" "velero" {
  count                 = local.velero["enabled"] ? 1 : 0
  repository            = local.velero["repository"]
  name                  = local.velero["name"]
  chart                 = local.velero["chart"]
  version               = local.velero["chart_version"]
  timeout               = local.velero["timeout"]
  force_update          = local.velero["force_update"]
  recreate_pods         = local.velero["recreate_pods"]
  wait                  = local.velero["wait"]
  atomic                = local.velero["atomic"]
  cleanup_on_fail       = local.velero["cleanup_on_fail"]
  dependency_update     = local.velero["dependency_update"]
  disable_crd_hooks     = local.velero["disable_crd_hooks"]
  disable_webhooks      = local.velero["disable_webhooks"]
  render_subchart_notes = local.velero["render_subchart_notes"]
  replace               = local.velero["replace"]
  reset_values          = local.velero["reset_values"]
  reuse_values          = local.velero["reuse_values"]
  skip_crds             = local.velero["skip_crds"]
  verify                = local.velero["verify"]
  values = compact([
    local.values_velero,
    local.velero["extra_values"]
  ])
  namespace = kubernetes_namespace.velero.*.metadata.0.name[count.index]

  depends_on = [
    kubectl_manifest.prometheus-operator_crds
  ]
}

resource "kubernetes_network_policy" "velero_default_deny" {
  count = local.velero["enabled"] && local.velero["default_network_policy"] ? 1 : 0

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
  count = local.velero["enabled"] && local.velero["default_network_policy"] ? 1 : 0

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
  count = local.velero["enabled"] && local.velero["default_network_policy"] ? 1 : 0

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

resource "kubernetes_manifest" "velero_snapshot_class" {
  count = (local.velero["enabled"] && local.velero["create_snapshot_class"]) ? 1 : 0
  manifest = {
    apiVersion = "snapshot.storage.k8s.io/v1"
    kind       = "VolumeSnapshotClass"
    metadata = {
      name = "default"
      labels = {
        "velero.io/csi-volumesnapshot-class" = "true"
      }
    }
    driver         = "pd.csi.storage.gke.io"
    deletionPolicy = "Delete"
  }
}
