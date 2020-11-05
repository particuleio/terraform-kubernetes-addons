module "eks-addons" {
  source        = "../.."

  alb_ingress = {
    enabled = true
  }

  nginx_ingress = {
    enabled = true
  }

  istio_operator = {
    enabled = true
  }

  cluster_autoscaler = {
    enabled      = true
    cluster_name = var.cluster-name
    extra_values = <<-EXTRA_VALUES
      image:
        repository: eu.gcr.io/k8s-artifacts-prod/autoscaling/cluster-autoscaler
      EXTRA_VALUES
  }

  external_dns = {
    enabled = true
  }

  cert_manager = {
    enabled                        = true
    acme_email                     = "kevin@particule.io"
    enable_default_cluster_issuers = true
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
            - grafana.clusterfrak-dynamics.io
          tls:
            - secretName: grafana-clusterfrak-dynamics-io
              hosts:
                - grafana.clusterfrak-dynamics.io
        persistence:
          enabled: true
          storageClassName: gp2
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
                storageClassName: gp2
                accessModes: ["ReadWriteOnce"]
                resources:
                  requests:
                    storage: 50Gi
      EXTRA_VALUES
  }

  fluentd_cloudwatch = {
    enabled = false
  }

  npd = {
    enabled = true
  }

  sealed_secrets = {
    enabled = true
  }

  cni_metrics_helper = {
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
          - karma.clusterfrak-dynamics.io
        tls:
          - secretName: karma-clusterfrak-dynamics-io
            hosts:
              - karma.clusterfrak-dynamics.io
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
