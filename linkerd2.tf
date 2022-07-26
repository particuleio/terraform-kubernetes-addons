locals {
  linkerd2 = merge(
    local.helm_defaults,
    {
      name               = local.helm_dependencies[index(local.helm_dependencies.*.name, "linkerd2")].name
      chart              = local.helm_dependencies[index(local.helm_dependencies.*.name, "linkerd2")].name
      repository         = local.helm_dependencies[index(local.helm_dependencies.*.name, "linkerd2")].repository
      chart_version      = local.helm_dependencies[index(local.helm_dependencies.*.name, "linkerd2")].version
      namespace          = "linkerd"
      create_ns          = true
      enabled            = false
      trust_anchor_pem   = null
      cluster_dns_domain = "cluster.local"
      ha                 = true
    },
    var.linkerd2
  )

  values_linkerd2 = <<-VALUES
    installNamespace: false
    namespace: ${local.linkerd2.namespace}
    cniEnabled: true
    enableEndpointSlices: true
    identity:
      issuer:
        scheme: kubernetes.io/tls
    identityTrustAnchorsPEM: |
      ${indent(2, local.linkerd2.enabled ? local.linkerd2["trust_anchor_pem"] == null ? tls_self_signed_cert.linkerd_trust_anchor.0.cert_pem : local.linkerd2["trust_anchor_pem"] : "")}
    proxyInjector:
      externalSecret: true
      caBundle: |
        ${indent(4, local.linkerd2.enabled ? tls_self_signed_cert.webhook_issuer_tls.0.cert_pem : "")}
    profileValidator:
      externalSecret: true
      caBundle: |
        ${indent(4, local.linkerd2.enabled ? tls_self_signed_cert.webhook_issuer_tls.0.cert_pem : "")}
    VALUES

  values_linkerd2_ha = <<-VALUES

    #
    # The below is taken from: https://github.com/linkerd/linkerd2/blob/main/charts/linkerd2/values-ha.yaml
    #

    enablePodAntiAffinity: true

    # proxy configuration
    proxy:
      # A better default for log collectors that require structured data
      logFormat: json
      resources:
        cpu:
          request: 100m
        memory:
          limit: 250Mi
          request: 20Mi

    # controller configuration
    controllerReplicas: 3
    controllerResources: &controller_resources
      cpu: &controller_resources_cpu
        limit: ""
        request: 100m
      memory:
        limit: 250Mi
        request: 50Mi
    destinationResources: *controller_resources

    # identity configuration
    identityResources:
      cpu: *controller_resources_cpu
      memory:
        limit: 250Mi
        request: 10Mi

    # heartbeat configuration
    heartbeatResources: *controller_resources

    # proxy injector configuration
    proxyInjectorResources: *controller_resources
    webhookFailurePolicy: Fail

    # service profile validator configuration
    spValidatorResources: *controller_resources
    VALUES

  linkerd2_manifests = {
    linkerd-identity-issuer = <<-VALUES
      apiVersion: cert-manager.io/v1
      kind: Certificate
      metadata:
        name: linkerd-identity-issuer
        namespace: ${local.linkerd2.namespace}
      spec:
        secretName: linkerd-identity-issuer
        revisionHistoryLimit: 3
        duration: 8h
        renewBefore: 4h
        issuerRef:
          name: linkerd-trust-anchor
          kind: Issuer
        commonName: identity.linkerd.cluster.local
        dnsNames:
        - identity.linkerd.cluster.local
        isCA: true
        privateKey:
          algorithm: ECDSA
        usages:
        - cert sign
        - crl sign
        - server auth
        - client auth
      VALUES

    linkerd-proxy-injector = <<-VALUES
      apiVersion: cert-manager.io/v1
      kind: Certificate
      metadata:
        name: linkerd-proxy-injector
        namespace: ${local.linkerd2.namespace}
      spec:
        secretName: linkerd-proxy-injector-k8s-tls
        revisionHistoryLimit: 3
        duration: 8h
        renewBefore: 4h
        issuerRef:
          name: webhook-issuer
          kind: Issuer
        commonName: linkerd-proxy-injector.${local.linkerd2.namespace}.svc
        dnsNames:
        - linkerd-proxy-injector.${local.linkerd2.namespace}.svc
        isCA: false
        privateKey:
          algorithm: ECDSA
        usages:
        - server auth
      VALUES

    linkerd-sp-validator = <<-VALUES
      apiVersion: cert-manager.io/v1
      kind: Certificate
      metadata:
        name: linkerd-sp-validator
        namespace: ${local.linkerd2.namespace}
      spec:
        secretName: linkerd-sp-validator-k8s-tls
        revisionHistoryLimit: 3
        duration: 8h
        renewBefore: 4h
        issuerRef:
          name: webhook-issuer
          kind: Issuer
        commonName: linkerd-sp-validator.${local.linkerd2.namespace}.svc
        dnsNames:
        - linkerd-sp-validator.${local.linkerd2.namespace}.svc
        isCA: false
        privateKey:
          algorithm: ECDSA
        usages:
        - server auth
      VALUES

    linkerd-trust-anchor = <<-VALUES
      apiVersion: cert-manager.io/v1
      kind: Issuer
      metadata:
        name: linkerd-trust-anchor
        namespace: ${local.linkerd2.namespace}
      spec:
        ca:
          secretName: linkerd-trust-anchor
      VALUES

    webhook-issuer = <<-VALUES
      apiVersion: cert-manager.io/v1
      kind: Issuer
      metadata:
        name: webhook-issuer
        namespace: ${local.linkerd2.namespace}
      spec:
        ca:
          secretName: webhook-issuer-tls
      VALUES
  }

}

resource "tls_private_key" "linkerd_trust_anchor" {
  count       = local.linkerd2["enabled"] && local.linkerd2["trust_anchor_pem"] == null ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "linkerd_trust_anchor" {
  count                 = local.linkerd2["enabled"] && local.linkerd2["trust_anchor_pem"] == null ? 1 : 0
  private_key_pem       = tls_private_key.linkerd_trust_anchor.0.private_key_pem
  validity_period_hours = 87600
  early_renewal_hours   = 78840
  is_ca_certificate     = true

  subject {
    common_name = "root.linkerd.cluster.local"
  }

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]
}

resource "kubernetes_secret" "linkerd_trust_anchor" {
  count = local.linkerd2["enabled"] && local.linkerd2["trust_anchor_pem"] == null ? 1 : 0
  metadata {
    name      = "linkerd-trust-anchor"
    namespace = local.linkerd2.create_ns ? kubernetes_namespace.linkerd2.0.metadata[0].name : local.linkerd2.namespace
  }

  data = {
    "tls.crt" = tls_self_signed_cert.linkerd_trust_anchor.0.cert_pem
    "tls.key" = tls_private_key.linkerd_trust_anchor.0.private_key_pem
  }

  type = "kubernetes.io/tls"
}

resource "tls_private_key" "webhook_issuer_tls" {
  count       = local.linkerd2["enabled"] ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "webhook_issuer_tls" {
  count                 = local.linkerd2["enabled"] ? 1 : 0
  private_key_pem       = tls_private_key.webhook_issuer_tls.0.private_key_pem
  validity_period_hours = 87600
  early_renewal_hours   = 78840
  is_ca_certificate     = true

  subject {
    common_name = "webhook.linkerd.cluster.local"
  }

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]
}

resource "kubernetes_secret" "webhook_issuer_tls" {
  count = local.linkerd2["enabled"] ? 1 : 0
  metadata {
    name      = "webhook-issuer-tls"
    namespace = local.linkerd2.create_ns ? kubernetes_namespace.linkerd2.0.metadata[0].name : local.linkerd2.namespace
  }

  data = {
    "tls.crt" = tls_self_signed_cert.webhook_issuer_tls.0.cert_pem
    "tls.key" = tls_private_key.webhook_issuer_tls.0.private_key_pem
  }

  type = "kubernetes.io/tls"
}

resource "kubernetes_namespace" "linkerd2" {
  count = local.linkerd2["enabled"] && local.linkerd2["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name                                  = local.linkerd2["namespace"]
      "linkerd.io/is-control-plane"         = "true"
      "config.linkerd.io/admission-webhook" = "disabled"
      "linkerd.io/control-plane-ns"         = local.linkerd2.namespace
    }

    annotations = {
      "linkerd.io/inject" = "disabled"
    }

    name = local.linkerd2["namespace"]
  }
}

resource "helm_release" "linkerd2" {
  count                 = local.linkerd2["enabled"] ? 1 : 0
  repository            = local.linkerd2["repository"]
  name                  = local.linkerd2["name"]
  chart                 = local.linkerd2["chart"]
  version               = local.linkerd2["chart_version"]
  timeout               = local.linkerd2["timeout"]
  force_update          = local.linkerd2["force_update"]
  recreate_pods         = local.linkerd2["recreate_pods"]
  wait                  = local.linkerd2["wait"]
  atomic                = local.linkerd2["atomic"]
  cleanup_on_fail       = local.linkerd2["cleanup_on_fail"]
  dependency_update     = local.linkerd2["dependency_update"]
  disable_crd_hooks     = local.linkerd2["disable_crd_hooks"]
  disable_webhooks      = local.linkerd2["disable_webhooks"]
  render_subchart_notes = local.linkerd2["render_subchart_notes"]
  replace               = local.linkerd2["replace"]
  reset_values          = local.linkerd2["reset_values"]
  reuse_values          = local.linkerd2["reuse_values"]
  skip_crds             = local.linkerd2["skip_crds"]
  verify                = local.linkerd2["verify"]
  values = compact([
    local.values_linkerd2,
    local.linkerd2["extra_values"],
    local.linkerd2.ha ? local.values_linkerd2_ha : null
  ])
  namespace = local.linkerd2["create_ns"] ? kubernetes_namespace.linkerd2.*.metadata.0.name[count.index] : local.linkerd2["namespace"]

  depends_on = [
    helm_release.linkerd2-cni
  ]
}

resource "kubectl_manifest" "linkerd" {
  for_each  = local.linkerd2.enabled ? local.linkerd2_manifests : {}
  yaml_body = each.value
}
