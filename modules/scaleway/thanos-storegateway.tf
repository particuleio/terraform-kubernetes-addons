locals {

  thanos-storegateway = { for k, v in var.thanos-storegateway : k => merge(
    local.helm_defaults,
    {
      chart                     = local.helm_dependencies[index(local.helm_dependencies.*.name, "thanos")].name
      repository                = local.helm_dependencies[index(local.helm_dependencies.*.name, "thanos")].repository
      chart_version             = local.helm_dependencies[index(local.helm_dependencies.*.name, "thanos")].version
      name                      = "${local.thanos["name"]}-storegateway-${k}"
      create_iam_resources_irsa = true
      iam_policy_override       = null
      enabled                   = false
      default_global_requests   = false
      default_global_limits     = false
      bucket                    = null
      region                    = null
    },
    v,
  ) }

  values_thanos-storegateway = { for k, v in local.thanos-storegateway : k => merge(
    {
      values = <<-VALUES
        global:
          security:
            allowInsecureImages: true
        image:
          registry: quay.io
          repository: thanos/thanos
          tag: v0.37.2
        objstoreConfig:
          type: S3
          config:
            bucket: ${v["bucket"]}
            region: ${v["region"] == null ? local.scaleway["region"] : v["region"]}
            endpoint: s3.${v["region"] == null ? local.scaleway["region"] : v["region"]}.scw.cloud
            signature_version2: false
            access_key: ${local.scaleway["scw_access_key"]}
            secret_key: ${local.scaleway["scw_secret_key"]}
        metrics:
          enabled: true
          serviceMonitor:
            enabled: ${local.kube-prometheus-stack["enabled"] ? "true" : "false"}
        query:
          enabled: false
        queryFrontend:
          enabled: false
        compactor:
          enabled: false
        storegateway:
          replicaCount: 2
          extraFlags:
            - --ignore-deletion-marks-delay=24h
          enabled: true
          pdb:
            create: true
            minAvailable: 1
        VALUES
    },
    v,
  ) }
}

resource "helm_release" "thanos-storegateway" {
  for_each              = { for k, v in local.thanos-storegateway : k => v if v["enabled"] }
  repository            = each.value["repository"]
  name                  = each.value["name"]
  chart                 = each.value["chart"]
  version               = each.value["chart_version"]
  timeout               = each.value["timeout"]
  force_update          = each.value["force_update"]
  recreate_pods         = each.value["recreate_pods"]
  wait                  = each.value["wait"]
  atomic                = each.value["atomic"]
  cleanup_on_fail       = each.value["cleanup_on_fail"]
  dependency_update     = each.value["dependency_update"]
  disable_crd_hooks     = each.value["disable_crd_hooks"]
  disable_webhooks      = each.value["disable_webhooks"]
  render_subchart_notes = each.value["render_subchart_notes"]
  replace               = each.value["replace"]
  reset_values          = each.value["reset_values"]
  reuse_values          = each.value["reuse_values"]
  skip_crds             = each.value["skip_crds"]
  verify                = each.value["verify"]
  values = compact([
    local.values_thanos-storegateway[each.key]["values"],
    each.value["default_global_requests"] ? local.values_thanos_global_requests : null,
    each.value["default_global_limits"] ? local.values_thanos_global_limits : null,
    each.value["extra_values"]
  ])
  namespace = local.thanos["create_ns"] ? kubernetes_namespace.thanos.*.metadata.0.name[0] : local.thanos["namespace"]

  depends_on = [
    helm_release.kube-prometheus-stack,
  ]
}
