module "kapsule" {
  source              = "particuleio/kapsule/scaleway"
  cluster_name        = "tkap"
  cluster_description = "tkap"

  node_pools = {
    tkap = {
      size        = 2
      max_size    = 3
      min_size    = 1
      autoscaling = true
    }
  }
}

module "kapsule-addons" {
  source = "../.."

  scaleway = {
    scw_access_key              = "SCWX0000000000000000"
    scw_secret_key              = "00000000-0000-0000-0000-000000000000"
    scw_default_organization_id = "00000000-0000-0000-0000-000000000000"
  }

  ingress-nginx = {
    enabled = true
  }

  istio-operator = {
    enabled = true
  }

  external-dns = {
    enabled = true
  }

  cert-manager = {
    enabled                   = true
    acme_http01_enabled       = true
    acme_email                = "kevin@particule.io"
    acme_dns01_enabled        = true
    acme_http01_ingress_class = "nginx"
  }

  cert-manager_scaleway_webhook_dns = {
    enabled = true
  }

  flux = {
    enabled      = true
    extra_values = <<-EXTRA_VALUES
      git:
        url: "ssh://git@gitlab.com/particuleio/gitops.git"
        pollInterval: "2m"
      rbac:
        create: false
      registry:
        automationInterval: "2m"
      EXTRA_VALUES
  }

  flux2 = {
    enabled               = true
    github_url            = "https://github.com/particuleio/gitops"
    github_token          = "000000000000000000000"
    repository            = "gitops"
    repository_visibility = "public"
    branch                = "main"
  }

  kube-prometheus-stack = {
    enabled      = true
    extra_values = <<-EXTRA_VALUES
      grafana:
        deploymentStrategy:
          type: Recreate
        ingress:
          enabled: true
          annotations:
            kubernetes.io/ingress.class: nginx
            cert-manager.io/cluster-issuer: "letsencrypt"
          hosts:
            - grafana.scw.particule.cloud
          tls:
            - secretName: grafana-scw-particule-cloud
              hosts:
                - grafana.scw.particule.cloud
        persistence:
          enabled: true
          storageClassName: scw-bssd
          accessModes:
            - ReadWriteOnce
          size: 10Gi
      prometheus:
        prometheusSpec:
          replicas: 1
          retention: 180d
          ruleSelectorNilUsesHelmValues: false
          serviceMonitorSelectorNilUsesHelmValues: false
          storageSpec:
            volumeClaimTemplate:
              spec:
                storageClassName: scw-bssd
                accessModes: ["ReadWriteOnce"]
                resources:
                  requests:
                    storage: 50Gi
      EXTRA_VALUES
  }

  npd = {
    enabled = true
  }

  sealed-secrets = {
    enabled = true
  }

  kong = {
    enabled = true
  }

  keycloak = {
    enabled = false
  }

  karma = {
    enabled      = true
    extra_values = <<-EXTRA_VALUES
      ingress:
        enabled: true
        path: /
        annotations:
          kubernetes.io/ingress.class: nginx
          cert-manager.io/cluster-issuer: "letsencrypt"
        hosts:
          - karma.scw.particule.cloud
        tls:
          - secretName: karma-scw-particule-cloud
            hosts:
              - karma.scw.particule.cloud
      env:
        - name: ALERTMANAGER_URI
          value: "http://prometheus-operator-alertmanager.monitoring.svc.cluster.local:9093"
        - name: ALERTMANAGER_PROXY
          value: "true"
        - name: FILTERS_DEFAULT
          value: "@state=active severity!=info severity!=none"
      EXTRA_VALUES
  }
}
