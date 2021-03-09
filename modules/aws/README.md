# terraform-kubernetes-addons:aws

[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/terraform-kubernetes-addons)
[![terraform-kubernetes-addons](https://github.com/particuleio/terraform-kubernetes-addons/workflows/terraform-kubernetes-addons/badge.svg)](https://github.com/particuleio/terraform-kubernetes-addons/actions?query=workflow%3Aterraform-kubernetes-addons)

## About

Provides various Kubernetes addons that are often used on Kubernetes with AWS

## Documentation

User guides, feature documentation and examples are available [here](https://github.com/particuleio/teks/)

## IAM permissions

This module can uses [IRSA](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/).

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13 |
| aws | ~> 3.0 |
| flux | ~> 0.0 |
| github | ~> 4.5 |
| helm | ~> 2.0 |
| kubectl | ~> 1.0 |
| kubernetes | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3.0 |
| flux | ~> 0.0 |
| github | ~> 4.5 |
| helm | ~> 2.0 |
| kubectl | ~> 1.0 |
| kubernetes | ~> 2.0 |
| random | n/a |
| time | n/a |
| tls | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| iam_assumable_role_aws-ebs-csi-driver | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 3.0 |
| iam_assumable_role_aws-for-fluent-bit | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 3.0 |
| iam_assumable_role_aws-load-balancer-controller | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 3.0 |
| iam_assumable_role_cert-manager | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 3.0 |
| iam_assumable_role_cluster-autoscaler | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 3.0 |
| iam_assumable_role_cni-metrics-helper | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 3.0 |
| iam_assumable_role_external-dns | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 3.0 |
| iam_assumable_role_kube-prometheus-stack_grafana | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 3.0 |
| iam_assumable_role_kube-prometheus-stack_thanos | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 3.0 |
| iam_assumable_role_loki-stack | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 3.0 |
| iam_assumable_role_prometheus-cloudwatch-exporter | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 3.0 |
| iam_assumable_role_thanos | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 3.0 |
| iam_assumable_role_thanos-storegateway | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 3.0 |
| kube-prometheus-stack_thanos_bucket | terraform-aws-modules/s3-bucket/aws | ~> 1.0 |
| loki_bucket | terraform-aws-modules/s3-bucket/aws | ~> 1.0 |
| thanos_bucket | terraform-aws-modules/s3-bucket/aws | ~> 1.0 |

## Resources

| Name |
|------|
| [aws_caller_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) |
| [aws_cloudwatch_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) |
| [aws_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) |
| [aws_iam_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) |
| [aws_region](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) |
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
| [kubernetes_storage_class](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) |
| [random_string](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) |
| [time_sleep](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) |
| [tls_cert_request](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/cert_request) |
| [tls_locally_signed_cert](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/locally_signed_cert) |
| [tls_private_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) |
| [tls_self_signed_cert](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws | AWS provider customization | `any` | `{}` | no |
| aws-ebs-csi-driver | Customize aws-ebs-csi-driver helm chart, see `aws-ebs-csi-driver.tf` | `any` | `{}` | no |
| aws-efs-csi-driver | Customize aws-efs-csi-driver helm chart, see `aws-efs-csi-driver.tf` | `any` | `{}` | no |
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
| flux2 | Customize Flux chart, see `flux2.tf` for supported values | `any` | `{}` | no |
| helm\_defaults | Customize default Helm behavior | `any` | `{}` | no |
| ingress-nginx | Customize ingress-nginx chart, see `nginx-ingress.tf` for supported values | `any` | `{}` | no |
| istio-operator | Customize istio operator deployment, see `istio_operator.tf` for supported values | `any` | `{}` | no |
| k8gb | Customize k8gb chart, see `k8gb.tf` for supported values | `any` | `{}` | no |
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
| prometheus-cloudwatch-exporter | Customize prometheus-cloudwatch-exporter chart, see `prometheus-cloudwatch-exporter.tf` for supported values | `any` | `{}` | no |
| promtail | Customize promtail chart, see `loki-stack.tf` for supported values | `any` | `{}` | no |
| sealed-secrets | Customize sealed-secrets chart, see `sealed-secrets.tf` for supported values | `any` | `{}` | no |
| strimzi-kafka-operator | Customize strimzi-kafka-operator chart, see `strimzi-kafka-operator.tf` for supported values | `any` | `{}` | no |
| tags | Map of tags for AWS resources | `map(any)` | `{}` | no |
| thanos | Customize thanos chart, see `thanos.tf` for supported values | `any` | `{}` | no |
| thanos-memcached | Customize thanos chart, see `thanos.tf` for supported values | `any` | `{}` | no |
| thanos-storegateway | Customize thanos chart, see `thanos.tf` for supported values | `any` | `{}` | no |
| thanos-tls-querier | Customize thanos chart, see `thanos.tf` for supported values | `any` | `{}` | no |
| vault | Customize Hashicorp Vault chart, see `vault.tf` for supported values | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| grafana\_password | n/a |
| loki-stack-ca | n/a |
| promtail-cert | n/a |
| promtail-key | n/a |
| thanos\_ca | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
