# terraform-kubernetes-addons:aws

[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/terraform-kubernetes-addons)
[![terraform-kubernetes-addons](https://github.com/particuleio/terraform-kubernetes-addons/workflows/terraform-kubernetes-addons/badge.svg)](https://github.com/particuleio/terraform-kubernetes-addons/actions?query=workflow%3Aterraform-kubernetes-addons)

## About

Provides various Kubernetes addons that are often used on Kubernetes with AWS

## Main features

* Common addons with associated IAM permissions if needed:
  * [cluster-autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler): scale worker nodes based on workload.
  * [external-dns](https://github.com/kubernetes-incubator/external-dns): sync ingress and service records in route53.
  * [cert-manager](https://github.com/jetstack/cert-manager): automatically generate TLS certificates, supports ACME v2.
  * [ingress-ingress](https://github.com/kubernetes/ingress-nginx): processes *Ingress* object and acts as a HTTP/HTTPS proxy (compatible with cert-manager).
  * [metrics-server](https://github.com/kubernetes-incubator/metrics-server): enable metrics API and horizontal pod scaling (HPA).
  * [prometheus-operator](https://github.com/prometheus-operator/kube-prometheus): Monitoring / Alerting / Dashboards.
  * [karma](https://github.com/prymitive/karma): An alertmanager dashboard
  * [node-problem-detector](https://github.com/kubernetes/node-problem-detector): Forwards node problems to Kubernetes events
  * [sealed-secrets](https://github.com/bitnami-labs/sealed-secrets): Technology agnostic, store secrets on git.
  * [istio-operator](https://istio.io): Service mesh for Kubernetes.
  * [cni-metrics-helper](https://docs.aws.amazon.com/eks/latest/userguide/cni-metrics-helper.html): Provides cloudwatch metrics for VPC CNI plugins.
  * [kong](https://konghq.com/kong): API Gateway ingress controller.
  * [keycloak](https://www.keycloak.org/) : Identity and access management
  * [aws-load-balancer-controller](https://aws.amazon.com/about-aws/whats-new/2020/10/introducing-aws-load-balancer-controller/): Use AWS ALB/NLB for ingress and services.
  * [aws-calico](https://github.com/aws/eks-charts/tree/master/stable/aws-calico): Use calico for network policy
  * [aws-node-termination-handler](https://github.com/aws/aws-node-termination-handler): Manage spot instance lifecyle
  * [aws-for-fluent-bit](https://github.com/aws/aws-for-fluent-bit): Cloudwatch logging with fluent bit instead of fluentd

## Documentation

User guides, feature documentation and examples are available [here](https://particuleio.github.io/teks/)

## IAM permissions

This module can uses [IRSA](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/).

## Terraform docs

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13 |
| aws | ~> 3.0 |
| helm | ~> 1.0 |
| kubectl | ~> 1.0 |
| kubernetes | ~> 1.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3.0 |
| helm | ~> 1.0 |
| kubectl | ~> 1.0 |
| kubernetes | ~> 1.0 |
| random | n/a |
| time | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws | AWS provider customization | `any` | `{}` | no |
| aws-for-fluent-bit | Customize aws-for-fluent-bit helm chart, see `aws-fluent-bit.tf` | `any` | `{}` | no |
| aws-load-balancer-controller | Customize aws-load-balancer-controller chart, see `aws-load-balancer-controller.tf` for supported values | `any` | `{}` | no |
| aws-node-termination-handler | Customize aws-node-termination-handler chart, see `aws-node-termination-handler.tf` | `any` | `{}` | no |
| calico | Customize calico helm chart, see `calico.tf` | `any` | `{}` | no |
| cert-manager | Customize cert-manager chart, see `cert-manager.tf` for supported values | `any` | `{}` | no |
| cluster-autoscaler | Customize cluster-autoscaler chart, see `cluster-autoscaler.tf` for supported values | `any` | `{}` | no |
| cluster-name | Name of the Kubernetes cluster | `string` | `"sample-cluster"` | no |
| cni-metrics-helper | Customize cni-metrics-helper deployment, see `cni-metrics-helper.tf` for supported values | `any` | `{}` | no |
| eks | EKS cluster inputs | `any` | `{}` | no |
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
| tags | Map of tags for AWS resources | `map` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| grafana\_password | n/a |

