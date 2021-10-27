locals {

  csi-external-snapshotter = merge(
    {
      enabled = false
      version = "v4.2.1"
    },
    var.csi-external-snapshotter
  )

  csi-external-snapshotter_yaml_files = [
    "https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${local.csi-external-snapshotter.version}/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml",
    "https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${local.csi-external-snapshotter.version}/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml",
    "https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${local.csi-external-snapshotter.version}/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml",
    "https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${local.csi-external-snapshotter.version}/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml",
    "https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${local.csi-external-snapshotter.version}/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml"
  ]

  #  csi-external-snapshotter_yaml_files = [
  #    "https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${local.csi-external-snapshotter.version}/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml",
  #    "https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${local.csi-external-snapshotter.version}/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml"
  #  ]

  #  csi-external-snapshotter_apply_crds = local.csi-external-snapshotter["enabled"] ? { for k, v in data.http.csi-external-snapshotter_crds : lower(join("/", compact([yamldecode(v.body).apiVersion, yamldecode(v.body).kind, lookup(yamldecode(v.body).metadata, "namespace", ""), yamldecode(v.body).metadata.name]))) => v.body
  # } : null
  #
  csi-external-snapshotter_apply = local.csi-external-snapshotter["enabled"] ? [for v in data.kubectl_file_documents.csi-external-snapshotter[0].documents : {
    data : yamldecode(v)
    content : v
    }
  ] : null

}

data "http" "csi-external-snapshotter" {
  for_each = local.csi-external-snapshotter.enabled ? toset(local.csi-external-snapshotter_yaml_files) : []
  url      = each.key
}

data "kubectl_file_documents" "csi-external-snapshotter" {
  count   = local.csi-external-snapshotter.enabled ? 1 : 0
  content = join("\n---\n", [for k, v in data.http.csi-external-snapshotter : v.body])
}

resource "kubectl_manifest" "csi-external-snapshotter" {
  for_each  = local.csi-external-snapshotter.enabled ? { for v in local.csi-external-snapshotter_apply : lower(join("/", compact([v.data.apiVersion, v.data.kind, lookup(v.data.metadata, "namespace", ""), v.data.metadata.name]))) => v.content } : {}
  yaml_body = each.value
}

#resource "kubectl_manifest" "csi-external-snapshotter" {
#  for_each  = local.csi-external-snapshotter.enabled ? local.csi-external-snapshotter_crds_apply : {}
#  yaml_body = each.value
#}
#
#
