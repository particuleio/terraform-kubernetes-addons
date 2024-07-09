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
    %{ if acme_http01_enabled }
    - http01:
        ingress:
          class: '${acme_http01_ingress_class}'
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
    %{ if acme_http01_enabled }
    - http01:
        ingress:
          class: '${acme_http01_ingress_class}'
    %{ endif }
