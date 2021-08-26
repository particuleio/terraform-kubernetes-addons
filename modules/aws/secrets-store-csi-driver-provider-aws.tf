locals {

  secrets-store-csi-driver-provider-aws = {
    enabled = local.secrets-store-csi-driver.enabled
    url     = "https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml"
  }

  secrets-store-csi-driver-provider-aws_apply = local.secrets-store-csi-driver-provider-aws.enabled ? [for v in data.kubectl_file_documents.secrets-store-csi-driver-provider-aws.0.documents : {
    data : yamldecode(v)
    content : v
    }
  ] : null
}

data "http" "secrets-store-csi-driver-provider-aws" {
  count = local.secrets-store-csi-driver-provider-aws.enabled ? 1 : 0
  url   = local.secrets-store-csi-driver-provider-aws.url
}

data "kubectl_file_documents" "secrets-store-csi-driver-provider-aws" {
  count   = local.secrets-store-csi-driver-provider-aws.enabled ? 1 : 0
  content = data.http.secrets-store-csi-driver-provider-aws[0].body
}

resource "kubectl_manifest" "secrets-store-csi-driver-provider-aws" {
  for_each  = local.secrets-store-csi-driver-provider-aws.enabled ? { for v in local.secrets-store-csi-driver-provider-aws_apply : lower(join("/", compact([v.data.apiVersion, v.data.kind, lookup(v.data.metadata, "namespace", ""), v.data.metadata.name]))) => v.content } : {}
  yaml_body = each.value
}
