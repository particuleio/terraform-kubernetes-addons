# terraform-kubernetes-addons

[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/terraform-kubernetes-addons)
[![terraform-kubernetes-addons](https://github.com/particuleio/terraform-kubernetes-addons/workflows/terraform-kubernetes-addons/badge.svg)](https://github.com/particuleio/terraform-kubernetes-addons/actions?query=workflow%3Aterraform-kubernetes-addons)

## Submodules

Submodules are used for specific cloud provider configuration such as IAM role for
AWS. For a Kubernetes vanilla cluster, generic addons should be used.

Any contribution supporting a new cloud provider is welcomed.

* [AWS](./modules/aws)
* [Scaleway](./modules/scaleway)

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13 |
| helm | ~> 1.0 |
| kubectl | ~> 1.0 |
| kubernetes | ~> 1.0 |

## Providers

| Name | Version |
|------|---------|
| helm | ~> 1.0 |
| kubectl | ~> 1.0 |
| kubernetes | ~> 1.0 |
| random | n/a |
| time | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cert-manager | Customize cert-manager chart, see `cert-manager.tf` for supported values | `any` | `{}` | no |
| cluster-autoscaler | Customize cluster-autoscaler chart, see `cluster-autoscaler.tf` for supported values | `any` | `{}` | no |
| cluster-name | Name of the Kubernetes cluster | `string` | `"sample-cluster"` | no |
| external-dns | Map of map for external-dns configuration: see `external_dns.tf` for supported values | `any` | `{}` | no |
| flux | Customize Flux chart, see `flux.tf` for supported values | `any` | `{}` | no |
| helm\_defaults | Customize default Helm behavior | `any` | `{}` | no |
| ingress-nginx | Customize ingress-nginx chart, see `nginx-ingress.tf` for supported values | `any` | `{}` | no |
| istio-operator | Customize istio operator deployment, see `istio_operator.tf` for supported values | `any` | `{}` | no |
| karma | Customize karma chart, see `karma.tf` for supported values | `any` | `{}` | no |
| keycloak | Customize keycloak chart, see `keycloak.tf` for supported values | `any` | `{}` | no |
| kong | Customize kong-ingress chart, see `kong.tf` for supported values | `any` | `{}` | no |
| kube-prometheus-stack | Customize kube-prometheus-stack chart, see `kube-prometheus-stack.tf` for supported values | `any` | `{}` | no |
| labels\_prefix | Custom label prefix used for network policy namespace matching | `string` | `"particule.io"` | no |
| metrics-server | Customize metrics-server chart, see `metrics_server.tf` for supported values | `any` | `{}` | no |
| npd | Customize node-problem-detector chart, see `npd.tf` for supported values | `any` | `{}` | no |
| priority-class | Customize a priority class for addons | `any` | `{}` | no |
| priority-class-ds | Customize a priority class for addons daemonsets | `any` | `{}` | no |
| sealed-secrets | Customize sealed-secrets chart, see `sealed-secrets.tf` for supported values | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| grafana\_password | n/a |
