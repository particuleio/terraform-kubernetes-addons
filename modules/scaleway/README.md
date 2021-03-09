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
| terraform | >= 0.13 |
| flux | ~> 0.0 |
| github | ~> 4.5 |
| helm | ~> 2.0 |
| kubectl | ~> 1.0 |
| kubernetes | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| flux | ~> 0.0 |
| github | ~> 4.5 |
| helm | ~> 2.0 |
| kubectl | ~> 1.0 |
| kubernetes | ~> 2.0 |
| random | n/a |
| time | n/a |
| tls | n/a |

## Modules

No Modules.

## Resources

| Name |
|------|
| [flux_install](https://registry.terraform.io/providers/fluxcd/flux/latest/docs/data-sources/install) |
| [flux_sync](https://registry.terraform.io/providers/fluxcd/flux/latest/docs/data-sources/sync) |
| [github_branch_default](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/branch_default) |
| [github_repository](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/repository) |
| [github_repository](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository) |
| [github_repository_deploy_key](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_deploy_key) |
| [github_repository_file](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_file) |
| [helm_release](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) |
| [kubectl_file_documents](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/file_documents) |
| [kubectl_manifest](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) |
| [kubectl_path_documents](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/path_documents) |
| [kubernetes_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) |
| [kubernetes_network_policy](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) |
| [kubernetes_priority_class](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/priority_class) |
| [kubernetes_role](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role) |
| [kubernetes_role_binding](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding) |
| [kubernetes_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) |
| [random_string](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) |
| [time_sleep](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) |
| [tls_private_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| admiralty | Customize admiralty chart, see `admiralty.tf` for supported values | `any` | `{}` | no |
| cert-manager | Customize cert-manager chart, see `cert-manager.tf` for supported values | `any` | `{}` | no |
| cert-manager\_scaleway\_webhook\_dns | Scaleway webhook dns customization | `any` | `{}` | no |
| cluster-autoscaler | Customize cluster-autoscaler chart, see `cluster-autoscaler.tf` for supported values | `any` | `{}` | no |
| cluster-name | Name of the Kubernetes cluster | `string` | `"sample-cluster"` | no |
| external-dns | Map of map for external-dns configuration: see `external_dns.tf` for supported values | `any` | `{}` | no |
| flux | Customize Flux chart, see `flux.tf` for supported values | `any` | `{}` | no |
| flux2 | Customize Flux chart, see `flux2.tf` for supported values | `any` | `{}` | no |
| helm\_defaults | Customize default Helm behavior | `any` | `{}` | no |
| ingress-nginx | Customize ingress-nginx chart, see `nginx-ingress.tf` for supported values | `any` | `{}` | no |
| istio-operator | Customize istio operator deployment, see `istio_operator.tf` for supported values | `any` | `{}` | no |
| kapsule | Kapsule cluster inputs | `any` | `{}` | no |
| karma | Customize karma chart, see `karma.tf` for supported values | `any` | `{}` | no |
| keycloak | Customize keycloak chart, see `keycloak.tf` for supported values | `any` | `{}` | no |
| kong | Customize kong-ingress chart, see `kong.tf` for supported values | `any` | `{}` | no |
| kube-prometheus-stack | Customize kube-prometheus-stack chart, see `kube-prometheus-stack.tf` for supported values | `any` | `{}` | no |
| kyverno | Customize kyverno chart, see `kyverno.tf` for supported values | `any` | `{}` | no |
| labels\_prefix | Custom label prefix used for network policy namespace matching | `string` | `"particule.io"` | no |
| loki-stack | Customize loki-stack chart, see `loki-stack.tf` for supported values | `any` | `{}` | no |
| metrics-server | Customize metrics-server chart, see `metrics_server.tf` for supported values | `any` | `{}` | no |
| npd | Customize node-problem-detector chart, see `npd.tf` for supported values | `any` | `{}` | no |
| priority-class | Customize a priority class for addons | `any` | `{}` | no |
| priority-class-ds | Customize a priority class for addons daemonsets | `any` | `{}` | no |
| prometheus-adapter | Customize prometheus-adapter chart, see `prometheus-adapter.tf` for supported values | `any` | `{}` | no |
| prometheus-blackbox-exporter | Customize prometheus-blackbox-exporter chart, see `prometheus-blackbox-exporter.tf` for supported values | `any` | `{}` | no |
| promtail | Customize promtail chart, see `loki-stack.tf` for supported values | `any` | `{}` | no |
| scaleway | Scaleway provider customization | `any` | `{}` | no |
| sealed-secrets | Customize sealed-secrets chart, see `sealed-secrets.tf` for supported values | `any` | `{}` | no |
| strimzi-kafka-operator | Customize strimzi-kafka-operator chart, see `strimzi-kafka-operator.tf` for supported values | `any` | `{}` | no |
| thanos | Customize thanos chart, see `thanos.tf` for supported values | `any` | `{}` | no |
| thanos-memcached | Customize thanos chart, see `thanos.tf` for supported values | `any` | `{}` | no |
| thanos-storegateway | Customize thanos chart, see `thanos.tf` for supported values | `any` | `{}` | no |
| thanos-tls-querier | Customize thanos chart, see `thanos.tf` for supported values | `any` | `{}` | no |
| vault | Customize Hashicorp Vault chart, see `vault.tf` for supported values | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| grafana\_password | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
