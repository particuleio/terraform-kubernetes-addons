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
    - dns01:
        route53:
          region: '${aws_region}'
          %{ if role_arn != "" }
          role: '${role_arn}'
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
    - dns01:
        route53:
          region: '${aws_region}'
          %{ if role_arn != "" }
          role: '${role_arn}'
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
