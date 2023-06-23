locals {
  ip-masq-agent = merge(
    {
      enabled = false
    },
    var.ip-masq-agent
  )
}

data "kubectl_filename_list" "ip_masq_agent_manifests" {
  pattern = "./manifests/gke-ip-masq/*.yaml"
}

resource "kubectl_manifest" "ip_masq_agent" {
  count     = local.ip-masq-agent.enabled ? length(data.kubectl_filename_list.ip_masq_agent_manifests.matches) : 0
  yaml_body = file(element(data.kubectl_filename_list.ip_masq_agent_manifests.matches, count.index))
}
