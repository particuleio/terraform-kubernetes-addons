module "kapsule-addons" {
  source        = "../.."

  nginx_ingress = {
    enabled = true
  }

  istio_operator = {
    enabled = true
  }

  external_dns = {
    enabled = true
  }

  metrics_server = {
    enabled       = true
  }

  flux = {
    enabled      = true
    extra_values = <<-EXTRA_VALUES
      git:
        url: "ssh://git@gitlab.com/myrepo/gitops.git"
        pollInterval: "2m"
      rbac:
        create: false
      registry:
        automationInterval: "2m"
      EXTRA_VALUES
  }

  prometheus_operator = {
    enabled       = true
    extra_values  = <<-EXTRA_VALUES
      grafana:
        deploymentStrategy:
          type: Recreate
        ingress:
          enabled: true
          annotations:
            kubernetes.io/ingress.class: nginx
            cert-manager.io/cluster-issuer: "letsencrypt"
          hosts:
            - grafana.particule.cloud
          tls:
            - secretName: grafana-particule-cloud
              hosts:
                - grafana.particule.cloud
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

  sealed_secrets = {
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
          - karma.particule.cloud
        tls:
          - secretName: karma-particule-cloud
            hosts:
              - karma.particule.cloud
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
