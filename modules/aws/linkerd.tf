locals {
  linkerd = merge(
    local.helm_defaults,
    {
      name               = local.helm_dependencies[index(local.helm_dependencies.*.name, "linkerd-control-plane")].name
      chart              = local.helm_dependencies[index(local.helm_dependencies.*.name, "linkerd-control-plane")].name
      repository         = local.helm_dependencies[index(local.helm_dependencies.*.name, "linkerd-control-plane")].repository
      chart_version      = local.helm_dependencies[index(local.helm_dependencies.*.name, "linkerd-control-plane")].version
      namespace          = "linkerd"
      create_ns          = true
      enabled            = false
      trust_anchor_pem   = null
      cluster_dns_domain = "cluster.local"
      ha                 = true
    },
    var.linkerd
  )

  values_linkerd = <<-VALUES
    identity:
      issuer:
        scheme: kubernetes.io/tls
    identityTrustAnchorsPEM: |
      ${indent(2, local.linkerd.enabled ? local.linkerd["trust_anchor_pem"] == null ? tls_self_signed_cert.linkerd_trust_anchor.0.cert_pem : local.linkerd["trust_anchor_pem"] : "")}
    policyValidator:
      externalSecret: true
      caBundle: |
        ${indent(4, local.linkerd.enabled ? tls_self_signed_cert.webhook_issuer_tls.0.cert_pem : "")}
    proxyInjector:
      externalSecret: true
      caBundle: |
        ${indent(4, local.linkerd.enabled ? tls_self_signed_cert.webhook_issuer_tls.0.cert_pem : "")}
    profileValidator:
      externalSecret: true
      caBundle: |
        ${indent(4, local.linkerd.enabled ? tls_self_signed_cert.webhook_issuer_tls.0.cert_pem : "")}
    VALUES

  values_linkerd_ha = <<-VALUES
    #
    # The below is taken from: https://github.com/linkerd/linkerd/blob/main/charts/linkerd/values-ha.yaml
    #

    # This values.yaml file contains the values needed to enable HA mode.
    # Usage:
    #   helm install -f values-ha.yaml

    # -- Create PodDisruptionBudget resources for each control plane workload
    enablePodDisruptionBudget: true

    # -- Specify a deployment strategy for each control plane workload
    deploymentStrategy:
      rollingUpdate:
        maxUnavailable: 1
        maxSurge: 25%

    # -- add PodAntiAffinity to each control plane workload
    enablePodAntiAffinity: true

    # nodeAffinity:

    # proxy configuration
    proxy:
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

  linkerd_manifests = {
    linkerd-trust-anchor = <<-VALUES
      apiVersion: cert-manager.io/v1
      kind: Issuer
      metadata:
        name: linkerd-trust-anchor
        namespace: ${local.linkerd.namespace}
      spec:
        ca:
          secretName: linkerd-trust-anchor
      VALUES

    linkerd-identity-issuer = <<-VALUES
      apiVersion: cert-manager.io/v1
      kind: Certificate
      metadata:
        name: linkerd-identity-issuer
        namespace: ${local.linkerd.namespace}
      spec:
        secretName: linkerd-identity-issuer
        revisionHistoryLimit: 3
        duration: 48h
        renewBefore: 25h
        issuerRef:
          name: linkerd-trust-anchor
          kind: Issuer
        commonName: identity.linkerd.${local.linkerd.cluster_dns_domain}
        dnsNames:
        - identity.linkerd.${local.linkerd.cluster_dns_domain}
        isCA: true
        privateKey:
          algorithm: ECDSA
        usages:
        - cert sign
        - crl sign
        - server auth
        - client auth
      VALUES

    webhook-issuer = <<-VALUES
      apiVersion: cert-manager.io/v1
      kind: Issuer
      metadata:
        name: webhook-issuer
        namespace: ${local.linkerd.namespace}
      spec:
        ca:
          secretName: webhook-issuer-tls
      VALUES

    linkerd-policy-validator = <<-VALUES
      apiVersion: cert-manager.io/v1
      kind: Certificate
      metadata:
        name: linkerd-policy-validator
        namespace: ${local.linkerd.namespace}
      spec:
        secretName: linkerd-policy-validator-k8s-tls
        duration: 24h
        renewBefore: 1h
        issuerRef:
          name: webhook-issuer
          kind: Issuer
        commonName: linkerd-policy-validator.${local.linkerd.namespace}.svc
        dnsNames:
        - linkerd-policy-validator.${local.linkerd.namespace}.svc
        isCA: false
        privateKey:
          algorithm: ECDSA
          encoding: PKCS8
        usages:
        - server auth
      VALUES

    linkerd-proxy-injector = <<-VALUES
      apiVersion: cert-manager.io/v1
      kind: Certificate
      metadata:
        name: linkerd-proxy-injector
        namespace: ${local.linkerd.namespace}
      spec:
        secretName: linkerd-proxy-injector-k8s-tls
        revisionHistoryLimit: 3
        duration: 24h
        renewBefore: 1h
        issuerRef:
          name: webhook-issuer
          kind: Issuer
        commonName: linkerd-proxy-injector.${local.linkerd.namespace}.svc
        dnsNames:
        - linkerd-proxy-injector.${local.linkerd.namespace}.svc
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
        namespace: ${local.linkerd.namespace}
      spec:
        secretName: linkerd-sp-validator-k8s-tls
        revisionHistoryLimit: 3
        duration: 24h
        renewBefore: 1h
        issuerRef:
          name: webhook-issuer
          kind: Issuer
        commonName: linkerd-sp-validator.${local.linkerd.namespace}.svc
        dnsNames:
        - linkerd-sp-validator.${local.linkerd.namespace}.svc
        isCA: false
        privateKey:
          algorithm: ECDSA
        usages:
        - server auth
      VALUES
  }

  linkerd-crds = merge(
    local.helm_defaults,
    {
      name          = local.helm_dependencies[index(local.helm_dependencies.*.name, "linkerd-crds")].name
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "linkerd-crds")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "linkerd-crds")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "linkerd-crds")].version
      namespace     = "linkerd"
      create_ns     = false
      enabled       = local.linkerd["enabled"] && !local.linkerd["skip_crds"]
    },
  )
}

resource "tls_private_key" "linkerd_trust_anchor" {
  count       = local.linkerd["enabled"] && local.linkerd["trust_anchor_pem"] == null ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "linkerd_trust_anchor" {
  count                 = local.linkerd["enabled"] && local.linkerd["trust_anchor_pem"] == null ? 1 : 0
  private_key_pem       = tls_private_key.linkerd_trust_anchor.0.private_key_pem
  validity_period_hours = 87600
  early_renewal_hours   = 78840
  is_ca_certificate     = true

  subject {
    common_name = "root.linkerd.${local.linkerd.cluster_dns_domain}"
  }

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]
}

resource "kubernetes_secret" "linkerd_trust_anchor" {
  count = local.linkerd["enabled"] && local.linkerd["trust_anchor_pem"] == null ? 1 : 0
  metadata {
    name      = "linkerd-trust-anchor"
    namespace = local.linkerd.create_ns ? kubernetes_namespace.linkerd.0.metadata[0].name : local.linkerd.namespace
  }

  data = {
    "tls.crt" = tls_self_signed_cert.linkerd_trust_anchor.0.cert_pem
    "tls.key" = tls_private_key.linkerd_trust_anchor.0.private_key_pem
  }

  type = "kubernetes.io/tls"
}

resource "tls_private_key" "webhook_issuer_tls" {
  count       = local.linkerd["enabled"] ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "webhook_issuer_tls" {
  count                 = local.linkerd["enabled"] ? 1 : 0
  private_key_pem       = tls_private_key.webhook_issuer_tls.0.private_key_pem
  validity_period_hours = 87600
  early_renewal_hours   = 78840
  is_ca_certificate     = true

  subject {
    common_name = "webhook.linkerd.${local.linkerd.cluster_dns_domain}"
  }

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]
}

resource "kubernetes_secret" "webhook_issuer_tls" {
  count = local.linkerd["enabled"] ? 1 : 0
  metadata {
    name      = "webhook-issuer-tls"
    namespace = local.linkerd.create_ns ? kubernetes_namespace.linkerd.0.metadata[0].name : local.linkerd.namespace
  }

  data = {
    "tls.crt" = tls_self_signed_cert.webhook_issuer_tls.0.cert_pem
    "tls.key" = tls_private_key.webhook_issuer_tls.0.private_key_pem
  }

  type = "kubernetes.io/tls"
}

resource "kubernetes_namespace" "linkerd" {
  count = local.linkerd["enabled"] && local.linkerd["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name                                  = local.linkerd["namespace"]
      "linkerd.io/is-control-plane"         = "true"
      "config.linkerd.io/admission-webhook" = "disabled"
      "linkerd.io/control-plane-ns"         = local.linkerd.namespace
    }

    annotations = {
      "linkerd.io/inject" = "disabled"
    }

    name = local.linkerd["namespace"]
  }
}

resource "helm_release" "linkerd-control-plane" {
  count                 = local.linkerd["enabled"] ? 1 : 0
  repository            = local.linkerd["repository"]
  name                  = local.linkerd["name"]
  chart                 = local.linkerd["chart"]
  version               = local.linkerd["chart_version"]
  timeout               = local.linkerd["timeout"]
  force_update          = local.linkerd["force_update"]
  recreate_pods         = local.linkerd["recreate_pods"]
  wait                  = local.linkerd["wait"]
  atomic                = local.linkerd["atomic"]
  cleanup_on_fail       = local.linkerd["cleanup_on_fail"]
  dependency_update     = local.linkerd["dependency_update"]
  disable_crd_hooks     = local.linkerd["disable_crd_hooks"]
  disable_webhooks      = local.linkerd["disable_webhooks"]
  render_subchart_notes = local.linkerd["render_subchart_notes"]
  replace               = local.linkerd["replace"]
  reset_values          = local.linkerd["reset_values"]
  reuse_values          = local.linkerd["reuse_values"]
  skip_crds             = local.linkerd["skip_crds"]
  verify                = local.linkerd["verify"]
  values = compact([
    local.values_linkerd,
    local.linkerd["extra_values"],
    local.linkerd.ha ? local.values_linkerd_ha : null
  ])
  namespace = local.linkerd["create_ns"] ? kubernetes_namespace.linkerd.*.metadata.0.name[count.index] : local.linkerd["namespace"]

  depends_on = [
    helm_release.linkerd2-cni,
    helm_release.linkerd-crds
  ]
}

resource "kubectl_manifest" "linkerd" {
  for_each  = local.linkerd.enabled ? local.linkerd_manifests : {}
  yaml_body = each.value
}

resource "helm_release" "linkerd-crds" {
  count                 = local.linkerd["enabled"] && !local.linkerd["skip_crds"] ? 1 : 0
  repository            = local.linkerd["repository"]
  name                  = local.linkerd-crds["name"]
  chart                 = local.linkerd-crds["chart"]
  version               = local.linkerd-crds["chart_version"]
  timeout               = local.linkerd["timeout"]
  force_update          = local.linkerd["force_update"]
  recreate_pods         = local.linkerd["recreate_pods"]
  wait                  = local.linkerd["wait"]
  atomic                = local.linkerd["atomic"]
  cleanup_on_fail       = local.linkerd["cleanup_on_fail"]
  dependency_update     = local.linkerd["dependency_update"]
  disable_crd_hooks     = local.linkerd["disable_crd_hooks"]
  disable_webhooks      = local.linkerd["disable_webhooks"]
  render_subchart_notes = local.linkerd["render_subchart_notes"]
  replace               = local.linkerd["replace"]
  reset_values          = local.linkerd["reset_values"]
  reuse_values          = local.linkerd["reuse_values"]
  skip_crds             = local.linkerd["skip_crds"]
  verify                = local.linkerd["verify"]
  values                = []
  namespace             = local.linkerd["create_ns"] ? kubernetes_namespace.linkerd.*.metadata.0.name[count.index] : local.linkerd["namespace"]
}
