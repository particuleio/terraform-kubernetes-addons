locals {

  scaleway_defaults = {
    scw_access_key              = ""
    scw_secret_key              = ""
    scw_default_organization_id = ""
    region                      = ""
  }

  scaleway = merge(
    local.scaleway_defaults,
    var.scaleway
  )

  tags          = var.tags


}
