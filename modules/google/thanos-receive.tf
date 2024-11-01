locals {

  thanos-receive = merge(
    local.helm_defaults,
    {
      name                    = local.helm_dependencies[index(local.helm_dependencies.*.name, "thanos")].name
      chart                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "thanos")].name
      repository              = local.helm_dependencies[index(local.helm_dependencies.*.name, "thanos")].repository
      chart_version           = local.helm_dependencies[index(local.helm_dependencies.*.name, "thanos")].version
      namespace               = "monitoring"
      create_iam_resources    = true
      iam_policy_override     = null
      create_ns               = false
      enabled                 = false
      default_network_policy  = true
      default_global_requests = false
      default_global_limits   = false
      create_bucket           = true
      bucket                  = "thanos-receive-store-${var.cluster-name}"
      bucket_force_destroy    = false
    },
    var.thanos-receive
  )

  values_thanos-receive = <<-VALUES
    receive:
      extraFlags:
        - --receive.hashrings-algorithm=ketama
      enabled: true
      replicaCount: 3
      replicationFactor: 2
      pdb:
        create: true
        minAvailable: 1
      service:
        additionalHeadless: true
      serviceAccount:
        annotations:
          iam.gke.io/gcp-service-account: "${local.thanos-receive["enabled"] && local.thanos-receive["create_iam_resources"] ? module.iam_assumable_sa_thanos-receive-receive[0].gcp_service_account_email : ""}"
    metrics:
      enabled: true
      serviceMonitor:
        enabled: ${local.kube-prometheus-stack["enabled"] ? "true" : "false"}
    compactor:
      strategyType: Recreate
      enabled: true
      serviceAccount:
        annotations:
          iam.gke.io/gcp-service-account: "${local.thanos-receive["enabled"] && local.thanos-receive["create_iam_resources"] ? module.iam_assumable_sa_thanos-receive-compactor[0].gcp_service_account_email : ""}"
    storegateway:
      replicaCount: 2
      enabled: true
      serviceAccount:
        annotations:
          iam.gke.io/gcp-service-account: "${local.thanos-receive["enabled"] && local.thanos-receive["create_iam_resources"] ? module.iam_assumable_sa_thanos-receive-sg[0].gcp_service_account_email : ""}"
      pdb:
        create: true
        minAvailable: 1
    VALUES

  values_thanos-receive_store_config = <<-VALUES
    objstoreConfig:
      type: GCS
      config:
        bucket: ${local.thanos-receive["bucket"]}
    VALUES

  values_thanos-receive_global_requests = <<-VALUES
    query:
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
    queryFrontend:
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
    compactor:
      resources:
        requests:
          cpu: 50m
          memory: 258Mi
    storegateway:
      resources:
        requests:
          cpu: 25m
          memory: 64Mi
    receive:
      resources:
        requests:
          cpu: 200m
          memory: 512Mi
    VALUES

  values_thanos-receive_global_limits = <<-VALUES
    query:
      resources:
        limits:
          memory: 128Mi
    queryFrontend:
      resources:
        limits:
          memory: 64Mi
    compactor:
      resources:
        limits:
          memory: 2Gi
    storegateway:
      resources:
        limits:
          memory: 1Gi
    receive:
      resources:
        limits:
          memory: 1Gi
    VALUES
}

module "iam_assumable_sa_thanos-receive-receive" {
  count               = local.thanos-receive["enabled"] ? 1 : 0
  source              = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version             = "~> 34.0"
  namespace           = local.thanos-receive["namespace"]
  project_id          = var.project_id
  name                = "${local.thanos-receive["name"]}-receive"
  use_existing_k8s_sa = true
  annotate_k8s_sa     = false
}

module "iam_assumable_sa_thanos-receive-compactor" {
  count               = local.thanos-receive["enabled"] ? 1 : 0
  source              = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version             = "~> 34.0"
  namespace           = local.thanos-receive["namespace"]
  project_id          = var.project_id
  name                = "${local.thanos-receive["name"]}-compactor"
  use_existing_k8s_sa = true
  annotate_k8s_sa     = false
}

module "iam_assumable_sa_thanos-receive-sg" {
  count               = local.thanos-receive["enabled"] ? 1 : 0
  source              = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version             = "~> 34.0"
  namespace           = local.thanos-receive["namespace"]
  project_id          = var.project_id
  name                = "${local.thanos-receive["name"]}-storegateway"
  use_existing_k8s_sa = true
  annotate_k8s_sa     = false
}

module "thanos-receive_bucket" {
  count = local.thanos-receive["enabled"] && local.thanos-receive["create_bucket"] ? 1 : 0

  source     = "terraform-google-modules/cloud-storage/google"
  version    = "~> 8.0"
  project_id = var.project_id
  location   = data.google_client_config.current.region

  names = [local.thanos-receive["bucket"]]
  encryption_key_names = {
    "${local.thanos-receive["bucket"]}" = module.thanos-receive_kms_bucket[0].keys.thanos-receive
  }
}

module "thanos-receive_kms_bucket" {
  count   = local.thanos-receive["enabled"] && local.thanos-receive["create_bucket"] ? 1 : 0
  source  = "terraform-google-modules/kms/google"
  version = "~> 3.0"

  project_id = var.project_id
  location   = data.google_client_config.current.region
  keyring    = "thanos-receive"
  keys       = ["thanos-receive"]
  owners = [
    "serviceAccount:service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com"
  ]
  set_owners_for = [
    "thanos-receive"
  ]
}

# GCS permissions for thanos-receive service account
resource "google_storage_bucket_iam_member" "thanos-receive-receive_gcs_iam_objectViewer_permissions" {
  count  = local.thanos-receive["enabled"] ? 1 : 0
  bucket = local.thanos-receive["bucket"]
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${module.iam_assumable_sa_thanos-receive-receive[0].gcp_service_account_email}"
  depends_on = [
    module.thanos-receive_bucket
  ]
}

resource "google_storage_bucket_iam_member" "thanos-receive_receive_gcs_iam_objectCreator_permissions" {
  count  = local.thanos-receive["enabled"] ? 1 : 0
  bucket = local.thanos-receive["bucket"]
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${module.iam_assumable_sa_thanos-receive-receive[0].gcp_service_account_email}"
  depends_on = [
    module.thanos-receive_bucket
  ]
}

# GCS permissions for thanos-receive compactor service account
resource "google_storage_bucket_iam_member" "thanos-receive_compactor_gcs_iam_objectViewer_permissions" {
  count  = local.thanos-receive["enabled"] ? 1 : 0
  bucket = local.thanos-receive["bucket"]
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${module.iam_assumable_sa_thanos-receive-compactor[0].gcp_service_account_email}"
  depends_on = [
    module.thanos-receive_bucket
  ]
}

resource "google_storage_bucket_iam_member" "thanos-receive_compactor_gcs_iam_objectCreator_permissions" {
  count  = local.thanos-receive["enabled"] ? 1 : 0
  bucket = local.thanos-receive["bucket"]
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${module.iam_assumable_sa_thanos-receive-compactor[0].gcp_service_account_email}"
  depends_on = [
    module.thanos-receive_bucket
  ]
}

resource "google_storage_bucket_iam_member" "thanos-receive_compactor_gcs_iam_legacyBucketWriter_permissions" {
  count  = local.thanos-receive["enabled"] ? 1 : 0
  bucket = local.thanos-receive["bucket"]
  role   = "roles/storage.legacyBucketWriter"
  member = "serviceAccount:${module.iam_assumable_sa_thanos-receive-compactor[0].gcp_service_account_email}"
  depends_on = [
    module.thanos-receive_bucket
  ]
}

# GCS permissions for thanos-receive storage gateway service account
resource "google_storage_bucket_iam_member" "thanos-receive_sg_gcs_iam_objectViewer_permissions" {
  count  = local.thanos-receive["enabled"] ? 1 : 0
  bucket = local.thanos-receive["bucket"]
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${module.iam_assumable_sa_thanos-receive-sg[0].gcp_service_account_email}"
  depends_on = [
    module.thanos-receive_bucket
  ]
}

resource "google_storage_bucket_iam_member" "thanos-receive_sg_gcs_iam_objectCreator_permissions" {
  count  = local.thanos-receive["enabled"] ? 1 : 0
  bucket = local.thanos-receive["bucket"]
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${module.iam_assumable_sa_thanos-receive-sg[0].gcp_service_account_email}"
  depends_on = [
    module.thanos-receive_bucket
  ]
}

resource "kubernetes_namespace" "thanos-receive" {
  count = local.thanos-receive["enabled"] && local.thanos-receive["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name                               = local.thanos-receive["namespace"]
      "${local.labels_prefix}/component" = "monitoring"
    }

    name = local.thanos-receive["namespace"]
  }
}

resource "helm_release" "thanos-receive" {
  count                 = local.thanos-receive["enabled"] ? 1 : 0
  repository            = local.thanos-receive["repository"]
  name                  = local.thanos-receive["name"]
  chart                 = local.thanos-receive["chart"]
  version               = local.thanos-receive["chart_version"]
  timeout               = local.thanos-receive["timeout"]
  force_update          = local.thanos-receive["force_update"]
  recreate_pods         = local.thanos-receive["recreate_pods"]
  wait                  = local.thanos-receive["wait"]
  atomic                = local.thanos-receive["atomic"]
  cleanup_on_fail       = local.thanos-receive["cleanup_on_fail"]
  dependency_update     = local.thanos-receive["dependency_update"]
  disable_crd_hooks     = local.thanos-receive["disable_crd_hooks"]
  disable_webhooks      = local.thanos-receive["disable_webhooks"]
  render_subchart_notes = local.thanos-receive["render_subchart_notes"]
  replace               = local.thanos-receive["replace"]
  reset_values          = local.thanos-receive["reset_values"]
  reuse_values          = local.thanos-receive["reuse_values"]
  skip_crds             = local.thanos-receive["skip_crds"]
  verify                = local.thanos-receive["verify"]
  values = compact([
    local.values_thanos-receive,
    local.values_thanos-receive_store_config,
    local.thanos-receive["default_global_requests"] ? local.values_thanos-receive_global_requests : null,
    local.thanos-receive["default_global_limits"] ? local.values_thanos-receive_global_limits : null,
    local.thanos-receive["extra_values"]
  ])
  namespace = local.thanos-receive["create_ns"] ? kubernetes_namespace.thanos-receive.*.metadata.0.name[count.index] : local.thanos-receive["namespace"]

  depends_on = [
    helm_release.kube-prometheus-stack,
  ]
}
