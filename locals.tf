locals {

  helm_defaults_defaults = {
    atomic                = false
    cleanup_on_fail       = false
    dependency_update     = false
    disable_crd_hooks     = false
    disable_webhooks      = false
    force_update          = false
    recreate_pods         = false
    render_subchart_notes = true
    replace               = false
    reset_values          = false
    reuse_values          = false
    skip_crds             = false
    timeout               = 3600
    verify                = false
    wait                  = true
    extra_values          = ""
  }

  helm_defaults = merge(
    local.helm_defaults_defaults,
    var.helm_defaults
  )

}
