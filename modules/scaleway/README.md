# terraform-kubernetes-addons

[![Build Status](https://github.com/particuleio/terraform-kubernetes-addons/workflows/Terraform/badge.svg)](https://github.com/particuleio/terraform-kubernetes-addons/actions?query=workflow%3Aterraform:scaleway)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/terraform-kubernetes-addons)

## About

Provides various addons that are often used on Kubernetes Kapsule with
Scaleway.

## Main features

* Common addons:
  * [cluster-autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler): scale worker nodes based on workload.
  * [external-dns](https://github.com/kubernetes-incubator/external-dns): sync ingress and service records in Scaleway DNS.
  * [nginx-ingress](https://github.com/kubernetes/ingress-nginx): processes *Ingress* object and acts as a HTTP/HTTPS proxy (compatible with cert-manager).
  * [metrics-server](https://github.com/kubernetes-incubator/metrics-server): enable metrics API and horizontal pod scaling (HPA).
  * [prometheus-operator](https://github.com/coreos/prometheus-operator): Monitoring / Alerting / Dashboards.
  * [karma](https://github.com/prymitive/karma): An alertmanager dashboard
  * [node-problem-detector](https://github.com/kubernetes/node-problem-detector): Forwards node problems to Kubernetes events
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

### Providers

| Name | Version |
|------|---------|
| helm | n/a |
| kubectl | n/a |
| kubernetes | n/a |
| random | n/a |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| scaleway | Scaleway provider customization | `any` | `{}` | no |
| cluster-name | Name of the Kubernetes cluster | `string` | `"sample-cluster"` | no |
| cluster\_autoscaler | Customize cluster-autoscaler chart, see `cluster_autoscaler.tf` for supported values | `any` | `{}` | no |
| kapsule | Kapsule cluster inputs | `any` | `{}` | no |
| external\_dns | Customize external-dns chart, see `external_dns.tf` for supported values | `any` | `{}` | no |
| flux | Customize fluxcd chart, see `flux.tf` for supported values | `any` | `{}` | no |
| helm\_defaults | Customize default Helm behavior | `any` | `{}` | no |
| istio\_operator | Customize istio operator deployment, see `istio_operator.tf` for supported values | `any` | `{}` | no |
| karma | Customize karma chart, see `karma.tf` for supported values | `any` | `{}` | no |
| keycloak | Customize keycloak chart, see `keycloak.tf` for supported values | `any` | `{}` | no |
| kong | Customize kong-ingress chart, see `kong.tf` for supported values | `any` | `{}` | no |
| metrics\_server | Customize metrics-server chart, see `metrics_server.tf` for supported values | `any` | `{}` | no |
| nginx\_ingress | Customize nginx-ingress chart, see `nginx-ingress.tf` for supported values | `any` | `{}` | no |
| npd | Customize node-problem-detector chart, see `npd.tf` for supported values | `any` | `{}` | no |
| priority\_class | Customize a priority class for addons | `any` | `{}` | no |
| priority\_class\_ds | Customize a priority class for addons daemonsets | `any` | `{}` | no |
| prometheus\_operator | Customize prometheus-operator chart, see `kube_prometheus.tf` for supported values | `any` | `{}` | no |
| sealed\_secrets | Customize sealed-secrets chart, see `sealed-secrets.tf` for supported values | `any` | `{}` | no |

### Outputs

| Name | Description |
|------|-------------|
| grafana\_password | n/a |

