# terraform-kubernetes-addons

[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/terraform-kubernetes-addons)
[![Build Status](https://github.com/particuleio/terraform-kubernetes-addons/workflows/terraform:scaleway/badge.svg)](https://github.com/particuleio/terraform-kubernetes-addons/actions?query=workflow%3Aterraform:scaleway)

## About

Provides various addons that are often used on Kubernetes Kapsule with
Scaleway.

## Main features

* Common addons:
  * [external-dns](https://github.com/kubernetes-incubator/external-dns): sync ingress and service records in Scaleway DNS.
  * [nginx-ingress](https://github.com/kubernetes/ingress-nginx): processes *Ingress* object and acts as a HTTP/HTTPS proxy (compatible with cert-manager).
  * [prometheus-operator](https://github.com/coreos/prometheus-operator): Monitoring / Alerting / Dashboards.
  * [karma](https://github.com/prymitive/karma): An alertmanager dashboard
  * [flux](https://github.com/weaveworks/flux): Continuous Delivery with Gitops workflow.
  * [sealed-secrets](https://github.com/bitnami-labs/sealed-secrets): Technology agnostic, store secrets on git.
  * [istio-operator](https://istio.io): Service mesh for Kubernetes.
  * [kong](https://konghq.com/kong): API Gateway ingress controller.
  * [keycloak](https://www.keycloak.org/) : Identity and access management

## Requirements

* [Terraform](https://www.terraform.io/intro/getting-started/install.html)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [helm](https://helm.sh/)

## Terraform docs

## Providers

| Name | Version |
|------|---------|
| helm | ~> 1.0 |
| kubernetes | ~> 1.0 |
| random | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cert-manager | Customize cert-manager chart, see `cert-manager.tf` for supported values | `any` | `{}` | no |
| cluster-name | Name of the Kubernetes cluster | `string` | `"sample-cluster"` | no |
| external-dns | Map of map for external-dns configuration: see `external_dns.tf` for supported values | `any` | `{}` | no |
| flux | Customize Flux chart, see `flux.tf` for supported values | `any` | `{}` | no |
| helm\_defaults | Customize default Helm behavior | `any` | `{}` | no |
| ingress-nginx | Customize ingress-nginx chart, see `nginx-ingress.tf` for supported values | `any` | `{}` | no |
| istio-operator | Customize istio operator deployment, see `istio_operator.tf` for supported values | `any` | `{}` | no |
| kapsule | Kapsule cluster inputs | `any` | `{}` | no |
| karma | Customize karma chart, see `karma.tf` for supported values | `any` | `{}` | no |
| keycloak | Customize keycloak chart, see `keycloak.tf` for supported values | `any` | `{}` | no |
| kong | Customize kong-ingress chart, see `kong.tf` for supported values | `any` | `{}` | no |
| kube-prometheus-stack | Customize kube-prometheus-stack chart, see `kube-prometheus-stack.tf` for supported values | `any` | `{}` | no |
| labels\_prefix | Custom label prefix used for network policy namespace matching | `string` | `"particule.io"` | no |
| priority-class | Customize a priority class for addons | `any` | `{}` | no |
| priority-class-ds | Customize a priority class for addons daemonsets | `any` | `{}` | no |
| scaleway | Scaleway provider customization | `any` | `{}` | no |
| sealed-secrets | Customize sealed-secrets chart, see `sealed-secrets.tf` for supported values | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| grafana\_password | n/a |
