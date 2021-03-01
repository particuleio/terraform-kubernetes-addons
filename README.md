# terraform-kubernetes-addons

[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/terraform-kubernetes-addons)
[![terraform-kubernetes-addons](https://github.com/particuleio/terraform-kubernetes-addons/workflows/terraform-kubernetes-addons/badge.svg)](https://github.com/particuleio/terraform-kubernetes-addons/actions?query=workflow%3Aterraform-kubernetes-addons)

## Main components

| Name | Description | Generic | AWS | Scaleway | GCP | Azure |
|------|-------------|:-------:|:---:|:--------:|:---:|:-----:|
| [aws-ebs-csi-driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver)                                                   | Enable new feature and the use of `gp3` volumes                                           | N/A                 | :heavy_check_mark:  | N/A                 | N/A                 | N/A                 |
| [aws-for-fluent-bit](https://github.com/aws/aws-for-fluent-bit)                                                               | Cloudwatch logging with fluent bit instead of fluentd                                     | N/A                 | :heavy_check_mark:  | N/A                 | N/A                 | N/A                 |
| [aws-load-balancer-controller](https://aws.amazon.com/about-aws/whats-new/2020/10/introducing-aws-load-balancer-controller/)  | Use AWS ALB/NLB for ingress and services                                                  | N/A                 | :heavy_check_mark:  | N/A                 | N/A                 | N/A                 |
| [aws-node-termination-handler](https://github.com/aws/aws-node-termination-handler)                                           | Manage spot instance lifecyle                                                             | N/A                 | :heavy_check_mark:  | N/A                 | N/A                 | N/A                 |
| [aws-calico](https://github.com/aws/eks-charts/tree/master/stable/aws-calico)                                                 | Use calico for network policy                                                             | N/A                 | :heavy_check_mark:  | N/A                 | N/A                 | N/A                 |
| [cert-manager](https://github.com/jetstack/cert-manager)                                                                      | automatically generate TLS certificates, supports ACME v2                                 | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :x:                 | N/A                 |
| [cluster-autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)                                 | scale worker nodes based on workload                                                      | N/A                 | :heavy_check_mark:  | Included            | Included            | Included            |
| [cni-metrics-helper](https://docs.aws.amazon.com/eks/latest/userguide/cni-metrics-helper.html)                                | Provides cloudwatch metrics for VPC CNI plugins                                           | N/A                 | :heavy_check_mark:  | N/A                 | N/A                 | N/A                 |
| [external-dns](https://github.com/kubernetes-incubator/external-dns)                                                          | sync ingress and service records in route53                                               | :x:                 | :heavy_check_mark:  | :heavy_check_mark:  | :x:                 | :x:                 |
| [ingress-nginx](https://github.com/kubernetes/ingress-nginx)                                                                  | processes `Ingress` object and acts as a HTTP/HTTPS proxy (compatible with cert-manager)  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :x:                 | :x:                 |
| [istio-operator](https://istio.io)                                                                                            | Service mesh for Kubernetes                                                               | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  |
| [karma](https://github.com/prymitive/karma)                                                                                   | An alertmanager dashboard                                                                 | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  |
| [keycloak](https://www.keycloak.org/)                                                                                         | Identity and access management                                                            | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  |
| [kong](https://konghq.com/kong)                                                                                               | API Gateway ingress controller                                                            | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :x:                 | :x:                 |
| [kube-prometheus-stack](https://github.com/prometheus-operator/kube-prometheus)                                               | Monitoring / Alerting / Dashboards                                                        | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :x:                 | :x:                 |
| [kyverno](https://github.com/kyverno/kyverno)                                                                                 | Kubernetes Native Policy Management                                                       | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  |
| [loki-stack](https://grafana.com/oss/loki/)                                                                                   | Grafana Loki logging stack                                                                | :heavy_check_mark:  | :heavy_check_mark:  | :construction:      | :x:                 | :x:                 |
| [promtail](https://grafana.com/docs/loki/latest/clients/promtail/)                                                            | Ship log to loki from other cluster (eg. mTLS)                                            | :construction:      | :heavy_check_mark:  | :construction:      | :x:                 | :x:                 |
| [metrics-server](https://github.com/kubernetes-incubator/metrics-server)                                                      | enable metrics API and horizontal pod scaling (HPA)                                       | :heavy_check_mark:  | :heavy_check_mark:  | Included            | Included            | Included            |
| [node-problem-detector](https://github.com/kubernetes/node-problem-detector)                                                  | Forwards node problems to Kubernetes events                                               | :heavy_check_mark:  | :heavy_check_mark:  | Included            | Included            | Included            |
| [sealed-secrets](https://github.com/bitnami-labs/sealed-secrets)                                                              | Technology agnostic, store secrets on git                                                 | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  |
| [strimzi-kafka-operator](https://github.com/strimzi/strimzi-kafka-operator)                                                   | Apache Kafka running on Kubernetes                                                        | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  |
| [thanos](https://thanos.io/)                                                                                                  | Open source, highly available Prometheus setup with long term storage capabilities        | :x:                 | :heavy_check_mark:  | :construction:      | :x:                 | :x:                 |
| [thanos-memcached](https://thanos.io/tip/components/query-frontend.md/#memcached)                                             | Open source, highly available Prometheus setup with long term storage capabilities        | :x:                 | :heavy_check_mark:  | :construction:      | :x:                 | :x:                 |
| [thanos-storegateway](https://thanos.io/)                                                                                     | Additional storegateway to query multiple object stores                                   | :x:                 | :heavy_check_mark:  | :construction:      | :x:                 | :x:                 |
| [thanos-tls-querier](https://thanos.io/tip/operating/cross-cluster-tls-communication.md/)                                     | Thanos TLS querier for cross cluster collection                                           | :x:                 | :heavy_check_mark:  | :construction:      | :x:                 | :x:                 |

## Submodules

Submodules are used for specific cloud provider configuration such as IAM role for
AWS. For a Kubernetes vanilla cluster, generic addons should be used.

Any contribution supporting a new cloud provider is welcomed.

* [AWS](./modules/aws)
* [Scaleway](./modules/scaleway)
* [GCP](./modules/gcp)
* [Azure](./modules/azure)

## Doc generation

Code formatting and documentation for variables and outputs is generated using
[pre-commit-terraform
hooks](https://github.com/antonbabenko/pre-commit-terraform) which uses
[terraform-docs](https://github.com/segmentio/terraform-docs).

Follow [these
instructions](https://github.com/antonbabenko/pre-commit-terraform#how-to-install)
to install pre-commit locally.

And install `terraform-docs` with `go get github.com/segmentio/terraform-docs`
or `brew install terraform-docs`.


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
| cert-manager | Customize cert-manager chart, see `cert-manager.tf` for supported values | `any` | `{}` | no |
| cluster-autoscaler | Customize cluster-autoscaler chart, see `cluster-autoscaler.tf` for supported values | `any` | `{}` | no |
| cluster-name | Name of the Kubernetes cluster | `string` | `"sample-cluster"` | no |
| external-dns | Map of map for external-dns configuration: see `external_dns.tf` for supported values | `any` | `{}` | no |
| flux | Customize Flux chart, see `flux.tf` for supported values | `any` | `{}` | no |
| flux2 | Customize Flux chart, see `flux2.tf` for supported values | `any` | `{}` | no |
| helm\_defaults | Customize default Helm behavior | `any` | `{}` | no |
| ingress-nginx | Customize ingress-nginx chart, see `nginx-ingress.tf` for supported values | `any` | `{}` | no |
| istio-operator | Customize istio operator deployment, see `istio_operator.tf` for supported values | `any` | `{}` | no |
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
| promtail | Customize promtail chart, see `loki-stack.tf` for supported values | `any` | `{}` | no |
| sealed-secrets | Customize sealed-secrets chart, see `sealed-secrets.tf` for supported values | `any` | `{}` | no |
| strimzi-kafka-operator | Customize strimzi-kafka-operator chart, see `strimzi-kafka-operator.tf` for supported values | `any` | `{}` | no |
| thanos | Customize thanos chart, see `thanos.tf` for supported values | `any` | `{}` | no |
| thanos-memcached | Customize thanos chart, see `thanos.tf` for supported values | `any` | `{}` | no |
| thanos-storegateway | Customize thanos chart, see `thanos.tf` for supported values | `any` | `{}` | no |
| thanos-tls-querier | Customize thanos chart, see `thanos.tf` for supported values | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| grafana\_password | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
