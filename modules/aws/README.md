# terraform-kubernetes-addons

[![Build Status](https://github.com/clusterfrak-dynamics/terraform-kubernetes-addons/workflows/Terraform/badge.svg)](https://github.com/clusterfrak-dynamics/terraform-kubernetes-addons/actions?query=workflow%3ATerraform)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/terraform-kubernetes-addons)

## About

Provides various addons that are often used on Kubernetes with AWS

## Main features

* Common addons with associated IAM permissions if needed:
  * [cluster-autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler): scale worker nodes based on workload.
  * [external-dns](https://github.com/kubernetes-incubator/external-dns): sync ingress and service records in route53.
  * [cert-manager](https://github.com/jetstack/cert-manager): automatically generate TLS certificates, supports ACME v2.
  * [kiam](https://github.com/uswitch/kiam): prevents pods to access EC2 metadata and enables pods to assume specific AWS IAM roles.
  * [nginx-ingress](https://github.com/kubernetes/ingress-nginx): processes *Ingress* object and acts as a HTTP/HTTPS proxy (compatible with cert-manager).
  * [metrics-server](https://github.com/kubernetes-incubator/metrics-server): enable metrics API and horizontal pod scaling (HPA).
  * [prometheus-operator](https://github.com/coreos/prometheus-operator): Monitoring / Alerting / Dashboards.
  * [karma](https://github.com/prymitive/karma): An alertmanager dashboard
  * [fluentd-cloudwatch](https://github.com/helm/charts/tree/master/incubator/fluentd-cloudwatch): forwards logs to AWS Cloudwatch.
  * [node-problem-detector](https://github.com/kubernetes/node-problem-detector): Forwards node problems to Kubernetes events
  * [flux](https://github.com/weaveworks/flux): Continous Delivery with Gitops workflow.
  * [sealed-secrets](https://github.com/bitnami-labs/sealed-secrets): Technology agnostic, store secrets on git.
  * [istio-operator](https://istio.io): Service mesh for Kubernetes.
  * [cni-metrics-helper](https://docs.aws.amazon.com/eks/latest/userguide/cni-metrics-helper.html): Provides cloudwatch metrics for VPC CNI plugins.
  * [kong](https://konghq.com/kong): API Gateway ingress controller.
  * [keycloak](https://www.keycloak.org/) : Identity and access management
  * [alb-ingress](https://github.com/kubernetes-sigs/aws-alb-ingress-controller): Use AWS ALB for ingress ressources.
  * [aws-calico](https://github.com/aws/eks-charts/tree/master/stable/aws-calico): Use calico for network policy
  * [aws-node-termination-handler](https://github.com/aws/aws-node-termination-handler): Manage spot instance lifecyle
  * [aws-for-fluent-bit](https://github.com/aws/aws-for-fluent-bit): Cloudwatch logging with fluent bit instead of fluentd

## Requirements

* [Terraform](https://www.terraform.io/intro/getting-started/install.html)
* [Terragrunt](https://github.com/gruntwork-io/terragrunt#install-terragrunt)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [helm](https://helm.sh/)
* [aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator)

## Documentation

User guides, feature documentation and examples are available [here](https://clusterfrak-dynamics.github.io/teks/)

## IAM permissions

This module can use either [IRSA](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/) which is the recommanded method or [Kiam](https://github.com/uswitch/kiam).

## About Kiam

Kiam prevents pods from accessing EC2 instances IAM role and therefore using the instances role to perform actions on AWS. It also allows pods to assume specific IAM roles if needed. To do so `kiam-agent` acts as an iptables proxy on nodes. It intercepts requests made to EC2 metadata and redirect them to a `kiam-server` that fetches IAM credentials and pass them to pods.

Kiam is running with an IAM user and use a secret key and a access key (AK/SK).

### Addons that require specific IAM permissions

Some addons interface with AWS API, for example:

* `cluster-autoscaler`
* `external-dns`
* `cert-manager`
* `virtual-kubelet`
* `cni-metric-helper`
* `flux`

## Terraform docs

### Providers

| Name | Version |
|------|---------|
| aws | n/a |
| helm | n/a |
| http | n/a |
| kubectl | n/a |
| kubernetes | n/a |
| random | n/a |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| aws | AWS provider customization | `any` | `{}` | no |
| cert\_manager | Customize cert-manager chart, see `cert_manager.tf` for supported values | `any` | `{}` | no |
| cluster-name | Name of the Kubernetes cluster | `string` | `"sample-cluster"` | no |
| cluster\_autoscaler | Customize cluster-autoscaler chart, see `cluster_autoscaler.tf` for supported values | `any` | `{}` | no |
| cni\_metrics\_helper | Customize cni-metrics-helper deployment, see `cni_metrics_helper.tf` for supported values | `any` | `{}` | no |
| eks | EKS cluster inputs | `any` | `{}` | no |
| external\_dns | Customize external-dns chart, see `external_dns.tf` for supported values | `any` | `{}` | no |
| fluentd\_cloudwatch | Customize fluentd-cloudwatch chart, see `fluentd-cloudwatch.tf` for supported values | `any` | `{}` | no |
| flux | Customize fluxcd chart, see `flux.tf` for supported values | `any` | `{}` | no |
| helm\_defaults | Customize default Helm behavior | `any` | `{}` | no |
| istio\_operator | Customize istio operator deployment, see `istio_operator.tf` for supported values | `any` | `{}` | no |
| karma | Customize karma chart, see `karma.tf` for supported values | `any` | `{}` | no |
| keycloak | Customize keycloak chart, see `keycloak.tf` for supported values | `any` | `{}` | no |
| kiam | Customize kiam chart, see `kiam.tf` for supported values | `any` | `{}` | no |
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
| flux-role-arn-irsa | n/a |
| flux-role-arn-kiam | n/a |
| flux-role-name-irsa | n/a |
| flux-role-name-kiam | n/a |
| grafana\_password | n/a |
| kiam-server-role-arn | n/a |
| kiam-server-role-name | n/a |

