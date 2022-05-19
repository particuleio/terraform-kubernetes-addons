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
      name_prefix               = "${var.cluster-name}-thanos-sg"
    },
    v,
  ) }

  values_thanos-storegateway = { for k, v in local.thanos-storegateway : k => merge(
    {
      values = <<-VALUES
        objstoreConfig:
          type: S3
          config:
            bucket: ${v["bucket"]}
            region: ${v["region"] == null ? data.aws_region.current.name : v["region"]}
            endpoint: s3.${v["region"] == null ? data.aws_region.current.name : v["region"]}.amazonaws.com
            sse_config:
              type: "SSE-S3"
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
          serviceAccount:
            annotations:
              eks.amazonaws.com/role-arn: "${v["enabled"] && v["create_iam_resources_irsa"] ? module.iam_assumable_role_thanos-storegateway[k].iam_role_arn : ""}"
          pdb:
            create: true
            minAvailable: 1
        VALUES
    },
    v,
  ) }
}

module "iam_assumable_role_thanos-storegateway" {
  for_each                     = local.thanos-storegateway
  source                       = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                      = "~> 5.0"
  create_role                  = each.value["enabled"] && each.value["create_iam_resources_irsa"]
  role_name                    = "${each.value.name_prefix}-${each.key}"
  provider_url                 = replace(var.eks["cluster_oidc_issuer_url"], "https://", "")
  role_policy_arns             = each.value["enabled"] && each.value["create_iam_resources_irsa"] ? [aws_iam_policy.thanos-storegateway[each.key].arn] : []
  number_of_role_policy_arns   = 1
  oidc_subjects_with_wildcards = ["system:serviceaccount:${local.thanos["namespace"]}:${each.value["name"]}-storegateway"]
  tags                         = local.tags
}

resource "aws_iam_policy" "thanos-storegateway" {
  for_each = { for k, v in local.thanos-storegateway : k => v if v["enabled"] && v["create_iam_resources_irsa"] }
  name     = "${each.value.name_prefix}-${each.key}"
  policy   = each.value["iam_policy_override"] == null ? data.aws_iam_policy_document.thanos-storegateway[each.key].json : each.value["iam_policy_override"]
  tags     = local.tags
}

data "aws_iam_policy_document" "thanos-storegateway" {

  for_each = { for k, v in local.thanos-storegateway : k => v if v["enabled"] && v["create_iam_resources_irsa"] }

  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = ["arn:${var.arn-partition}:s3:::${each.value["bucket"]}"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:*Object"
    ]

    resources = ["arn:${var.arn-partition}:s3:::${each.value["bucket"]}/*"]
  }
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
