locals {

  kong_crd_version = "kong-${local.kong.chart_version}"

  kong_crds = "https://raw.githubusercontent.com/Kong/charts/${local.kong_crd_version}/charts/kong/crds/custom-resource-definitions.yaml"

  kong_crds_apply = local.kong.enabled && local.kong.manage_crds ? [for v in data.kubectl_file_documents.kong_crds.0.documents : {
    data : yamldecode(v)
    content : v
    }
  ] : null
}

data "http" "kong_crds" {
  count = local.kong.enabled && local.kong.manage_crds ? 1 : 0
  url   = local.kong_crds
}

data "kubectl_file_documents" "kong_crds" {
  count   = local.kong.enabled && local.kong.manage_crds ? 1 : 0
  content = data.http.kong_crds[0].response_body
}

resource "kubectl_manifest" "kong_crds" {
  for_each          = local.kong.enabled && local.kong.manage_crds ? { for v in local.kong_crds_apply : lower(join("/", compact([v.data.apiVersion, v.data.kind, lookup(v.data.metadata, "namespace", ""), v.data.metadata.name]))) => v.content } : {}
  yaml_body         = each.value
  server_side_apply = true
  force_conflicts   = true
}
