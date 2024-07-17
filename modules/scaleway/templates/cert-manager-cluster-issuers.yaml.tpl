---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: '${acme_email}'
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    %{ if acme_dns01_enabled }
    %{ if acme_dns01_provider == "route53" }
    - dns01:
        route53:
          hostedZoneID: ${acme_dns01_hosted_zone_id}
          %{ if acme_dns01_region != ""  }
          region: '${acme_dns01_region}'
          %{ endif }
          accessKeyIDSecretRef:
            name: ${acme_dns01_aws_secret}
            key: ${acme_dns01_aws_access_key_id}
          secretAccessKeySecretRef:
            name: ${acme_dns01_aws_secret}
            key: ${acme_dns01_aws_access_key_secret}
    %{ else }
    %{if acme_dns01_provider == "google" }
    - dns01:
        clouddns:
          project: '${acme_dns01_google_project}'
          serviceAccountSecretRef:
            name: '${acme_dns01_google_secret}'
            key: '${acme_dns01_google_service_account_key}'
    %{ else }
    - dns01:
        webhook:
          groupName: acme.scaleway.com
          solverName: scaleway
          config:
            accessKeySecretRef:
              key: SCW_ACCESS_KEY
              name: '${secret_name}'
            secretKeySecretRef:
              key: SCW_SECRET_KEY
              name: '${secret_name}'
    %{ endif }
    %{ endif }
    %{ endif }
    %{ if acme_http01_enabled }
    - http01:
        ingress:
          class: '${acme_http01_ingress_class}'
      %{ if acme_dns01_enabled }
      selector:
        matchLabels:
          "use-http01-solver": "true"
      %{ endif }
    %{ endif }
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: '${acme_email}'
    privateKeySecretRef:
      name: letsencrypt
    solvers:
    %{ if acme_dns01_enabled }
    %{ if acme_dns01_provider == "route53" }
    - dns01:
        route53:
          hostedZoneID: ${acme_dns01_hosted_zone_id}
          %{ if acme_dns01_region != ""  }
          region: '${acme_dns01_region}'
          %{ endif }
          accessKeyIDSecretRef:
            name: ${acme_dns01_aws_secret}
            key: ${acme_dns01_aws_access_key_id}
          secretAccessKeySecretRef:
            name: ${acme_dns01_aws_secret}
            key: ${acme_dns01_aws_access_key_secret}
    %{ else }
    %{if acme_dns01_provider == "google" }
    - dns01:
        clouddns:
          project: '${acme_dns01_google_project}'
          serviceAccountSecretRef:
            name: '${acme_dns01_google_secret}'
            key: '${acme_dns01_google_service_account_key}'
    %{ else }
    - dns01:
        webhook:
          groupName: acme.scaleway.com
          solverName: scaleway
          config:
            accessKeySecretRef:
              key: SCW_ACCESS_KEY
              name: '${secret_name}'
            secretKeySecretRef:
              key: SCW_SECRET_KEY
              name: '${secret_name}'
    %{ endif }
    %{ endif }
    %{ endif }
    %{ if acme_http01_enabled }
    - http01:
        ingress:
          class: '${acme_http01_ingress_class}'
      %{ if acme_dns01_enabled }
      selector:
        matchLabels:
          "use-http01-solver": "true"
      %{ endif }
    %{ endif }
