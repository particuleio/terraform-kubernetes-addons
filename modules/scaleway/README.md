# terraform-kubernetes-addons:scaleway

[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/terraform-kubernetes-addons)
[![terraform-kubernetes-addons](https://github.com/particuleio/terraform-kubernetes-addons/workflows/terraform-kubernetes-addons/badge.svg)](https://github.com/particuleio/terraform-kubernetes-addons/actions?query=workflow%3Aterraform-kubernetes-addons)

## About

Provides various addons that are often used on Kubernetes Kapsule with
Scaleway.

## Documentation

User guides, feature documentation and examples are available [here](https://github.com/particuleio/tkap/)

## Terraform docs

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_flux"></a> [flux](#requirement\_flux) | 1.0.0-rc.5 |
| <a name="requirement_github"></a> [github](#requirement\_github) | ~> 5.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_http"></a> [http](#requirement\_http) | >= 3 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0, != 2.12 |
| <a name="requirement_scaleway"></a> [scaleway](#requirement\_scaleway) | >= 2.2.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_flux"></a> [flux](#provider\_flux) | 1.0.0-rc.5 |
| <a name="provider_github"></a> [github](#provider\_github) | ~> 5.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.0 |
| <a name="provider_http"></a> [http](#provider\_http) | >= 3 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | ~> 1.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.0, != 2.12 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_scaleway"></a> [scaleway](#provider\_scaleway) | >= 2.2.0 |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | ~> 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [flux_bootstrap_git.flux](https://registry.terraform.io/providers/fluxcd/flux/1.0.0-rc.5/docs/resources/bootstrap_git) | resource |
| [github_branch_default.main](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/branch_default) | resource |
| [github_repository.main](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository) | resource |
| [github_repository_deploy_key.main](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_deploy_key) | resource |
| [helm_release.admiralty](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.cert-manager](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.cert-manager-csi-driver](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.external-dns](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.ingress-nginx](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.k8gb](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.karma](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.keda](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.kong](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.kube-prometheus-stack](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.linkerd-control-plane](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.linkerd-crds](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.linkerd-viz](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.linkerd2-cni](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.loki-stack](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.prometheus-adapter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.prometheus-blackbox-exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.promtail](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.scaleway-webhook-dns](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.sealed-secrets](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.thanos](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.thanos-memcached](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.thanos-storegateway](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.thanos-tls-querier](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.traefik](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.victoria-metrics-k8s-stack](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.cert-manager_cluster_issuers](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.csi-external-snapshotter](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.kong_crds](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.linkerd](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.linkerd-viz](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.prometheus-operator_crds](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_config_map.loki-stack_grafana_ds](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_namespace.admiralty](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.cert-manager](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.external-dns](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.flux2](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.ingress-nginx](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.k8gb](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.karma](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.keda](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.kong](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.kube-prometheus-stack](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.linkerd](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.linkerd-viz](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.linkerd2-cni](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.loki-stack](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.prometheus-adapter](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.prometheus-blackbox-exporter](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.promtail](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.sealed-secrets](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.thanos](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.traefik](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.victoria-metrics-k8s-stack](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_network_policy.admiralty_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.admiralty_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.cert-manager_allow_control_plane](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.cert-manager_allow_monitoring](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.cert-manager_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.cert-manager_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.external-dns_allow_monitoring](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.external-dns_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.external-dns_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.flux2_allow_monitoring](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.flux2_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.ingress-nginx_allow_control_plane](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.ingress-nginx_allow_ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.ingress-nginx_allow_linkerd_viz](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.ingress-nginx_allow_monitoring](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.ingress-nginx_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.ingress-nginx_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.k8gb_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.k8gb_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.karma_allow_ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.karma_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.karma_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.keda_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.keda_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.kong_allow_ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.kong_allow_monitoring](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.kong_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.kong_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.kube-prometheus-stack_allow_control_plane](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.kube-prometheus-stack_allow_ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.kube-prometheus-stack_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.kube-prometheus-stack_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.linkerd-viz_allow_control_plane](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.linkerd-viz_allow_monitoring](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.linkerd-viz_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.linkerd-viz_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.linkerd2-cni_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.linkerd2-cni_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.loki-stack_allow_ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.loki-stack_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.loki-stack_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.prometheus-adapter_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.prometheus-adapter_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.prometheus-blackbox-exporter_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.prometheus-blackbox-exporter_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.promtail_allow_ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.promtail_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.promtail_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.sealed-secrets_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.sealed-secrets_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.traefik_allow_ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.traefik_allow_monitoring](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.traefik_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.traefik_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.victoria-metrics-k8s-stack_allow_control_plane](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.victoria-metrics-k8s-stack_allow_ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.victoria-metrics-k8s-stack_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.victoria-metrics-k8s-stack_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_priority_class.kubernetes_addons](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/priority_class) | resource |
| [kubernetes_priority_class.kubernetes_addons_ds](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/priority_class) | resource |
| [kubernetes_secret.cert-manager_scaleway_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.external-dns_scaleway_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.kube-prometheus-stack_thanos](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.linkerd_trust_anchor](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.loki-stack-ca](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.promtail-tls](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.thanos-ca](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.webhook_issuer_tls](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [random_string.grafana_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [scaleway_object_bucket.kube-prometheus-stack_thanos_bucket](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/object_bucket) | resource |
| [scaleway_object_bucket.loki_bucket](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/object_bucket) | resource |
| [scaleway_object_bucket.thanos_bucket](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/object_bucket) | resource |
| [time_sleep.cert-manager_sleep](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [tls_cert_request.promtail-csr](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/cert_request) | resource |
| [tls_cert_request.thanos-tls-querier-cert-csr](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/cert_request) | resource |
| [tls_locally_signed_cert.promtail-cert](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/locally_signed_cert) | resource |
| [tls_locally_signed_cert.thanos-tls-querier-cert](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/locally_signed_cert) | resource |
| [tls_private_key.identity](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.linkerd_trust_anchor](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.loki-stack-ca-key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.promtail-key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.thanos-tls-querier-ca-key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.thanos-tls-querier-cert-key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.webhook_issuer_tls](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_self_signed_cert.linkerd_trust_anchor](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
| [tls_self_signed_cert.loki-stack-ca-cert](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
| [tls_self_signed_cert.thanos-tls-querier-ca-cert](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
| [tls_self_signed_cert.webhook_issuer_tls](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
| [github_repository.main](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/repository) | data source |
| [http_http.csi-external-snapshotter](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.kong_crds](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.prometheus-operator_crds](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.prometheus-operator_version](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [kubectl_file_documents.csi-external-snapshotter](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/file_documents) | data source |
| [kubectl_file_documents.kong_crds](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/file_documents) | data source |
| [kubectl_path_documents.cert-manager_cluster_issuers](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/path_documents) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admiralty"></a> [admiralty](#input\_admiralty) | Customize admiralty chart, see `admiralty.tf` for supported values | `any` | `{}` | no |
| <a name="input_cert-manager"></a> [cert-manager](#input\_cert-manager) | Customize cert-manager chart, see `cert-manager.tf` for supported values | `any` | `{}` | no |
| <a name="input_cert-manager-csi-driver"></a> [cert-manager-csi-driver](#input\_cert-manager-csi-driver) | Customize cert-manager-csi-driver chart, see `cert-manager.tf` for supported values | `any` | `{}` | no |
| <a name="input_cert-manager_scaleway_webhook_dns"></a> [cert-manager\_scaleway\_webhook\_dns](#input\_cert-manager\_scaleway\_webhook\_dns) | Scaleway webhook dns customization | `any` | `{}` | no |
| <a name="input_cluster-autoscaler"></a> [cluster-autoscaler](#input\_cluster-autoscaler) | Customize cluster-autoscaler chart, see `cluster-autoscaler.tf` for supported values | `any` | `{}` | no |
| <a name="input_cluster-name"></a> [cluster-name](#input\_cluster-name) | Name of the Kubernetes cluster | `string` | `"sample-cluster"` | no |
| <a name="input_csi-external-snapshotter"></a> [csi-external-snapshotter](#input\_csi-external-snapshotter) | Customize csi-external-snapshotter, see `csi-external-snapshotter.tf` for supported values | `any` | `{}` | no |
| <a name="input_external-dns"></a> [external-dns](#input\_external-dns) | Map of map for external-dns configuration: see `external_dns.tf` for supported values | `any` | `{}` | no |
| <a name="input_flux2"></a> [flux2](#input\_flux2) | Customize Flux chart, see `flux2.tf` for supported values | `any` | `{}` | no |
| <a name="input_helm_defaults"></a> [helm\_defaults](#input\_helm\_defaults) | Customize default Helm behavior | `any` | `{}` | no |
| <a name="input_ingress-nginx"></a> [ingress-nginx](#input\_ingress-nginx) | Customize ingress-nginx chart, see `nginx-ingress.tf` for supported values | `any` | `{}` | no |
| <a name="input_ip-masq-agent"></a> [ip-masq-agent](#input\_ip-masq-agent) | Configure ip masq agent chart, see `ip-masq-agent.tf` for supported values. This addon works only on GCP. | `any` | `{}` | no |
| <a name="input_k8gb"></a> [k8gb](#input\_k8gb) | Customize k8gb chart, see `k8gb.tf` for supported values | `any` | `{}` | no |
| <a name="input_kapsule"></a> [kapsule](#input\_kapsule) | Kapsule cluster inputs | `any` | `{}` | no |
| <a name="input_karma"></a> [karma](#input\_karma) | Customize karma chart, see `karma.tf` for supported values | `any` | `{}` | no |
| <a name="input_keda"></a> [keda](#input\_keda) | Customize keda chart, see `keda.tf` for supported values | `any` | `{}` | no |
| <a name="input_kong"></a> [kong](#input\_kong) | Customize kong-ingress chart, see `kong.tf` for supported values | `any` | `{}` | no |
| <a name="input_kube-prometheus-stack"></a> [kube-prometheus-stack](#input\_kube-prometheus-stack) | Customize kube-prometheus-stack chart, see `kube-prometheus-stack.tf` for supported values | `any` | `{}` | no |
| <a name="input_labels_prefix"></a> [labels\_prefix](#input\_labels\_prefix) | Custom label prefix used for network policy namespace matching | `string` | `"particule.io"` | no |
| <a name="input_linkerd"></a> [linkerd](#input\_linkerd) | Customize linkerd chart, see `linkerd.tf` for supported values | `any` | `{}` | no |
| <a name="input_linkerd-viz"></a> [linkerd-viz](#input\_linkerd-viz) | Customize linkerd-viz chart, see `linkerd-viz.tf` for supported values | `any` | `{}` | no |
| <a name="input_linkerd2"></a> [linkerd2](#input\_linkerd2) | Customize linkerd2 chart, see `linkerd2.tf` for supported values | `any` | `{}` | no |
| <a name="input_linkerd2-cni"></a> [linkerd2-cni](#input\_linkerd2-cni) | Customize linkerd2-cni chart, see `linkerd2-cni.tf` for supported values | `any` | `{}` | no |
| <a name="input_loki-stack"></a> [loki-stack](#input\_loki-stack) | Customize loki-stack chart, see `loki-stack.tf` for supported values | `any` | `{}` | no |
| <a name="input_metrics-server"></a> [metrics-server](#input\_metrics-server) | Customize metrics-server chart, see `metrics_server.tf` for supported values | `any` | `{}` | no |
| <a name="input_npd"></a> [npd](#input\_npd) | Customize node-problem-detector chart, see `npd.tf` for supported values | `any` | `{}` | no |
| <a name="input_priority-class"></a> [priority-class](#input\_priority-class) | Customize a priority class for addons | `any` | `{}` | no |
| <a name="input_priority-class-ds"></a> [priority-class-ds](#input\_priority-class-ds) | Customize a priority class for addons daemonsets | `any` | `{}` | no |
| <a name="input_prometheus-adapter"></a> [prometheus-adapter](#input\_prometheus-adapter) | Customize prometheus-adapter chart, see `prometheus-adapter.tf` for supported values | `any` | `{}` | no |
| <a name="input_prometheus-blackbox-exporter"></a> [prometheus-blackbox-exporter](#input\_prometheus-blackbox-exporter) | Customize prometheus-blackbox-exporter chart, see `prometheus-blackbox-exporter.tf` for supported values | `any` | `{}` | no |
| <a name="input_promtail"></a> [promtail](#input\_promtail) | Customize promtail chart, see `loki-stack.tf` for supported values | `any` | `{}` | no |
| <a name="input_scaleway"></a> [scaleway](#input\_scaleway) | Scaleway provider customization | `any` | `{}` | no |
| <a name="input_sealed-secrets"></a> [sealed-secrets](#input\_sealed-secrets) | Customize sealed-secrets chart, see `sealed-secrets.tf` for supported values | `any` | `{}` | no |
| <a name="input_secrets-store-csi-driver"></a> [secrets-store-csi-driver](#input\_secrets-store-csi-driver) | Customize secrets-store-csi-driver chart, see `secrets-store-csi-driver.tf` for supported values | `any` | `{}` | no |
| <a name="input_thanos"></a> [thanos](#input\_thanos) | Customize thanos chart, see `thanos.tf` for supported values | `any` | `{}` | no |
| <a name="input_thanos-memcached"></a> [thanos-memcached](#input\_thanos-memcached) | Customize thanos chart, see `thanos.tf` for supported values | `any` | `{}` | no |
| <a name="input_thanos-storegateway"></a> [thanos-storegateway](#input\_thanos-storegateway) | Customize thanos chart, see `thanos.tf` for supported values | `any` | `{}` | no |
| <a name="input_thanos-tls-querier"></a> [thanos-tls-querier](#input\_thanos-tls-querier) | Customize thanos chart, see `thanos.tf` for supported values | `any` | `{}` | no |
| <a name="input_tigera-operator"></a> [tigera-operator](#input\_tigera-operator) | Customize tigera-operator chart, see `tigera-operator.tf` for supported values | `any` | `{}` | no |
| <a name="input_traefik"></a> [traefik](#input\_traefik) | Customize traefik chart, see `traefik.tf` for supported values | `any` | `{}` | no |
| <a name="input_victoria-metrics-k8s-stack"></a> [victoria-metrics-k8s-stack](#input\_victoria-metrics-k8s-stack) | Customize Victoria Metrics chart, see `victoria-metrics-k8s-stack.tf` for supported values | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_grafana_password"></a> [grafana\_password](#output\_grafana\_password) | n/a |
| <a name="output_loki-stack-ca"></a> [loki-stack-ca](#output\_loki-stack-ca) | n/a |
| <a name="output_promtail-cert"></a> [promtail-cert](#output\_promtail-cert) | n/a |
| <a name="output_promtail-key"></a> [promtail-key](#output\_promtail-key) | n/a |
| <a name="output_thanos_ca"></a> [thanos\_ca](#output\_thanos\_ca) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
