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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.42 |
| <a name="requirement_flux"></a> [flux](#requirement\_flux) | 1.0.0-rc.5 |
| <a name="requirement_github"></a> [github](#requirement\_github) | ~> 5.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_http"></a> [http](#requirement\_http) | >= 3 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0, != 2.12 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.42 |
| <a name="provider_aws.ecr_public"></a> [aws.ecr\_public](#provider\_aws.ecr\_public) | >= 4.42 |
| <a name="provider_flux"></a> [flux](#provider\_flux) | 1.0.0-rc.5 |
| <a name="provider_github"></a> [github](#provider\_github) | ~> 5.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.0 |
| <a name="provider_http"></a> [http](#provider\_http) | >= 3 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | ~> 1.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.0, != 2.12 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | ~> 4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_iam_assumable_role_aws-ebs-csi-driver"></a> [iam\_assumable\_role\_aws-ebs-csi-driver](#module\_iam\_assumable\_role\_aws-ebs-csi-driver) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 5.0 |
| <a name="module_iam_assumable_role_aws-efs-csi-driver"></a> [iam\_assumable\_role\_aws-efs-csi-driver](#module\_iam\_assumable\_role\_aws-efs-csi-driver) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 5.0 |
| <a name="module_iam_assumable_role_aws-for-fluent-bit"></a> [iam\_assumable\_role\_aws-for-fluent-bit](#module\_iam\_assumable\_role\_aws-for-fluent-bit) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 5.0 |
| <a name="module_iam_assumable_role_aws-load-balancer-controller"></a> [iam\_assumable\_role\_aws-load-balancer-controller](#module\_iam\_assumable\_role\_aws-load-balancer-controller) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 5.0 |
| <a name="module_iam_assumable_role_cert-manager"></a> [iam\_assumable\_role\_cert-manager](#module\_iam\_assumable\_role\_cert-manager) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 5.0 |
| <a name="module_iam_assumable_role_cluster-autoscaler"></a> [iam\_assumable\_role\_cluster-autoscaler](#module\_iam\_assumable\_role\_cluster-autoscaler) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 5.0 |
| <a name="module_iam_assumable_role_cni-metrics-helper"></a> [iam\_assumable\_role\_cni-metrics-helper](#module\_iam\_assumable\_role\_cni-metrics-helper) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 5.0 |
| <a name="module_iam_assumable_role_external-dns"></a> [iam\_assumable\_role\_external-dns](#module\_iam\_assumable\_role\_external-dns) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 5.0 |
| <a name="module_iam_assumable_role_kube-prometheus-stack_grafana"></a> [iam\_assumable\_role\_kube-prometheus-stack\_grafana](#module\_iam\_assumable\_role\_kube-prometheus-stack\_grafana) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 5.0 |
| <a name="module_iam_assumable_role_kube-prometheus-stack_thanos"></a> [iam\_assumable\_role\_kube-prometheus-stack\_thanos](#module\_iam\_assumable\_role\_kube-prometheus-stack\_thanos) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 5.0 |
| <a name="module_iam_assumable_role_loki-stack"></a> [iam\_assumable\_role\_loki-stack](#module\_iam\_assumable\_role\_loki-stack) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 5.0 |
| <a name="module_iam_assumable_role_prometheus-cloudwatch-exporter"></a> [iam\_assumable\_role\_prometheus-cloudwatch-exporter](#module\_iam\_assumable\_role\_prometheus-cloudwatch-exporter) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 5.0 |
| <a name="module_iam_assumable_role_thanos"></a> [iam\_assumable\_role\_thanos](#module\_iam\_assumable\_role\_thanos) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 5.0 |
| <a name="module_iam_assumable_role_thanos-storegateway"></a> [iam\_assumable\_role\_thanos-storegateway](#module\_iam\_assumable\_role\_thanos-storegateway) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 5.0 |
| <a name="module_iam_assumable_role_velero"></a> [iam\_assumable\_role\_velero](#module\_iam\_assumable\_role\_velero) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 5.0 |
| <a name="module_iam_assumable_role_yet-another-cloudwatch-exporter"></a> [iam\_assumable\_role\_yet-another-cloudwatch-exporter](#module\_iam\_assumable\_role\_yet-another-cloudwatch-exporter) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 5.0 |
| <a name="module_karpenter"></a> [karpenter](#module\_karpenter) | terraform-aws-modules/eks/aws//modules/karpenter | ~> 19.0 |
| <a name="module_kube-prometheus-stack_thanos_bucket"></a> [kube-prometheus-stack\_thanos\_bucket](#module\_kube-prometheus-stack\_thanos\_bucket) | terraform-aws-modules/s3-bucket/aws | ~> 3.0 |
| <a name="module_loki_bucket"></a> [loki\_bucket](#module\_loki\_bucket) | terraform-aws-modules/s3-bucket/aws | ~> 3.0 |
| <a name="module_s3_logging_bucket"></a> [s3\_logging\_bucket](#module\_s3\_logging\_bucket) | terraform-aws-modules/s3-bucket/aws | ~> 3.0 |
| <a name="module_security-group-efs-csi-driver"></a> [security-group-efs-csi-driver](#module\_security-group-efs-csi-driver) | terraform-aws-modules/security-group/aws//modules/nfs | ~> 5.0 |
| <a name="module_thanos_bucket"></a> [thanos\_bucket](#module\_thanos\_bucket) | terraform-aws-modules/s3-bucket/aws | ~> 3.0 |
| <a name="module_velero_thanos_bucket"></a> [velero\_thanos\_bucket](#module\_velero\_thanos\_bucket) | terraform-aws-modules/s3-bucket/aws | ~> 3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.aws-for-fluent-bit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_efs_file_system.aws-efs-csi-driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system) | resource |
| [aws_efs_mount_target.aws-efs-csi-driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target) | resource |
| [aws_iam_policy.aws-ebs-csi-driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.aws-efs-csi-driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.aws-for-fluent-bit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.aws-load-balancer-controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.cert-manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.cluster-autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.cni-metrics-helper](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.external-dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.karpenter_additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.kube-prometheus-stack_grafana](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.kube-prometheus-stack_thanos](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.loki-stack](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.prometheus-cloudwatch-exporter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.thanos](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.thanos-storegateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.velero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.yet-another-cloudwatch-exporter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_kms_alias.aws-ebs-csi-driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.aws-ebs-csi-driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [flux_bootstrap_git.flux](https://registry.terraform.io/providers/fluxcd/flux/1.0.0-rc.5/docs/resources/bootstrap_git) | resource |
| [github_branch_default.main](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/branch_default) | resource |
| [github_repository.main](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository) | resource |
| [github_repository_deploy_key.main](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_deploy_key) | resource |
| [helm_release.admiralty](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.aws-ebs-csi-driver](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.aws-efs-csi-driver](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.aws-for-fluent-bit](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.aws-load-balancer-controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.aws-node-termination-handler](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.cert-manager](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.cert-manager-csi-driver](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.cluster-autoscaler](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.external-dns](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.ingress-nginx](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.k8gb](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.karma](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.keda](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.kong](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.kube-prometheus-stack](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.linkerd-control-plane](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.linkerd-crds](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.linkerd-viz](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.linkerd2-cni](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.loki-stack](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.metrics-server](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.node-problem-detector](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.prometheus-adapter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.prometheus-blackbox-exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.prometheus-cloudwatch-exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.promtail](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.sealed-secrets](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.secrets-store-csi-driver](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.thanos](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.thanos-memcached](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.thanos-storegateway](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.thanos-tls-querier](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.tigera-operator](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.traefik](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.velero](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.victoria-metrics-k8s-stack](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.yet-another-cloudwatch-exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.aws-ebs-csi-driver_vsc](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.calico_crds](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.cert-manager_cluster_issuers](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.cni-metrics-helper](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.csi-external-snapshotter](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.kong_crds](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.linkerd](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.linkerd-viz](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.prometheus-operator_crds](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.secrets-store-csi-driver-provider-aws](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.tigera-operator_crds](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_config_map.loki-stack_grafana_ds](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_namespace.admiralty](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.aws-ebs-csi-driver](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.aws-efs-csi-driver](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.aws-for-fluent-bit](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.aws-load-balancer-controller](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.aws-node-termination-handler](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.cert-manager](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.cluster-autoscaler](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.external-dns](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.flux2](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.ingress-nginx](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.k8gb](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.karma](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.karpenter](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.keda](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.kong](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.kube-prometheus-stack](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.linkerd](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.linkerd-viz](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.linkerd2-cni](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.loki-stack](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.metrics-server](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.node-problem-detector](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.prometheus-adapter](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.prometheus-blackbox-exporter](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.prometheus-cloudwatch-exporter](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.promtail](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.sealed-secrets](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.secrets-store-csi-driver](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.thanos](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.tigera-operator](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.traefik](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.velero](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.victoria-metrics-k8s-stack](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.yet-another-cloudwatch-exporter](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_network_policy.admiralty_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.admiralty_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.aws-ebs-csi-driver_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.aws-ebs-csi-driver_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.aws-efs-csi-driver_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.aws-efs-csi-driver_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.aws-for-fluent-bit_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.aws-for-fluent-bit_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.aws-load-balancer-controller_allow_control_plane](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.aws-load-balancer-controller_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.aws-load-balancer-controller_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.aws-node-termination-handler_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.aws-node-termination-handler_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.cert-manager_allow_control_plane](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.cert-manager_allow_monitoring](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.cert-manager_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.cert-manager_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.cluster-autoscaler_allow_monitoring](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.cluster-autoscaler_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.cluster-autoscaler_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
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
| [kubernetes_network_policy.karpenter_allow_control_plane](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.karpenter_allow_monitoring](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.karpenter_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.karpenter_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
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
| [kubernetes_network_policy.metrics-server_allow_control_plane](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.metrics-server_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.metrics-server_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.npd_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.npd_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.prometheus-adapter_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.prometheus-adapter_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.prometheus-blackbox-exporter_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.prometheus-blackbox-exporter_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.prometheus-cloudwatch-exporter_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.prometheus-cloudwatch-exporter_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.promtail_allow_ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.promtail_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.promtail_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.sealed-secrets_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.sealed-secrets_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.secrets-store-csi-driver_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.secrets-store-csi-driver_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.tigera-operator_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.tigera-operator_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.traefik_allow_ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.traefik_allow_monitoring](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.traefik_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.traefik_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.velero_allow_monitoring](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.velero_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.velero_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.victoria-metrics-k8s-stack_allow_control_plane](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.victoria-metrics-k8s-stack_allow_ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.victoria-metrics-k8s-stack_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.victoria-metrics-k8s-stack_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.yet-another-cloudwatch-exporter_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.yet-another-cloudwatch-exporter_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_priority_class.kubernetes_addons](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/priority_class) | resource |
| [kubernetes_priority_class.kubernetes_addons_ds](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/priority_class) | resource |
| [kubernetes_secret.kube-prometheus-stack_thanos](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.linkerd_trust_anchor](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.loki-stack-ca](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.promtail-tls](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.thanos-ca](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.webhook_issuer_tls](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_storage_class.aws-ebs-csi-driver](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |
| [kubernetes_storage_class.aws-efs-csi-driver](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |
| [random_string.grafana_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
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
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ecrpublic_authorization_token.token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecrpublic_authorization_token) | data source |
| [aws_iam_policy_document.aws-ebs-csi-driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.aws-ebs-csi-driver_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.aws-ebs-csi-driver_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.aws-efs-csi-driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.aws-efs-csi-driver_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.aws-for-fluent-bit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.aws-load-balancer-controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cert-manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cluster-autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cni-metrics-helper](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.external-dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.karpenter_additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kube-prometheus-stack_grafana](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kube-prometheus-stack_thanos](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.loki-stack](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.prometheus-cloudwatch-exporter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.thanos](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.thanos-storegateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.velero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.velero_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.velero_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.yet-another-cloudwatch-exporter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [github_repository.main](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/repository) | data source |
| [http_http.calico_crds](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.csi-external-snapshotter](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.kong_crds](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.prometheus-operator_crds](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.prometheus-operator_version](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.secrets-store-csi-driver-provider-aws](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.tigera-operator_crds](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [kubectl_file_documents.calico_crds](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/file_documents) | data source |
| [kubectl_file_documents.csi-external-snapshotter](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/file_documents) | data source |
| [kubectl_file_documents.kong_crds](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/file_documents) | data source |
| [kubectl_file_documents.secrets-store-csi-driver-provider-aws](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/file_documents) | data source |
| [kubectl_file_documents.tigera-operator_crds](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/file_documents) | data source |
| [kubectl_path_documents.cert-manager_cluster_issuers](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/path_documents) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admiralty"></a> [admiralty](#input\_admiralty) | Customize admiralty chart, see `admiralty.tf` for supported values | `any` | `{}` | no |
| <a name="input_arn-partition"></a> [arn-partition](#input\_arn-partition) | ARN partition | `string` | `""` | no |
| <a name="input_aws"></a> [aws](#input\_aws) | AWS provider customization | `any` | `{}` | no |
| <a name="input_aws-ebs-csi-driver"></a> [aws-ebs-csi-driver](#input\_aws-ebs-csi-driver) | Customize aws-ebs-csi-driver helm chart, see `aws-ebs-csi-driver.tf` | `any` | `{}` | no |
| <a name="input_aws-efs-csi-driver"></a> [aws-efs-csi-driver](#input\_aws-efs-csi-driver) | Customize aws-efs-csi-driver helm chart, see `aws-efs-csi-driver.tf` | `any` | `{}` | no |
| <a name="input_aws-for-fluent-bit"></a> [aws-for-fluent-bit](#input\_aws-for-fluent-bit) | Customize aws-for-fluent-bit helm chart, see `aws-fluent-bit.tf` | `any` | `{}` | no |
| <a name="input_aws-load-balancer-controller"></a> [aws-load-balancer-controller](#input\_aws-load-balancer-controller) | Customize aws-load-balancer-controller chart, see `aws-load-balancer-controller.tf` for supported values | `any` | `{}` | no |
| <a name="input_aws-node-termination-handler"></a> [aws-node-termination-handler](#input\_aws-node-termination-handler) | Customize aws-node-termination-handler chart, see `aws-node-termination-handler.tf` | `any` | `{}` | no |
| <a name="input_cert-manager"></a> [cert-manager](#input\_cert-manager) | Customize cert-manager chart, see `cert-manager.tf` for supported values | `any` | `{}` | no |
| <a name="input_cert-manager-csi-driver"></a> [cert-manager-csi-driver](#input\_cert-manager-csi-driver) | Customize cert-manager-csi-driver chart, see `cert-manager.tf` for supported values | `any` | `{}` | no |
| <a name="input_cluster-autoscaler"></a> [cluster-autoscaler](#input\_cluster-autoscaler) | Customize cluster-autoscaler chart, see `cluster-autoscaler.tf` for supported values | `any` | `{}` | no |
| <a name="input_cluster-name"></a> [cluster-name](#input\_cluster-name) | Name of the Kubernetes cluster | `string` | `"sample-cluster"` | no |
| <a name="input_cni-metrics-helper"></a> [cni-metrics-helper](#input\_cni-metrics-helper) | Customize cni-metrics-helper deployment, see `cni-metrics-helper.tf` for supported values | `any` | `{}` | no |
| <a name="input_csi-external-snapshotter"></a> [csi-external-snapshotter](#input\_csi-external-snapshotter) | Customize csi-external-snapshotter, see `csi-external-snapshotter.tf` for supported values | `any` | `{}` | no |
| <a name="input_eks"></a> [eks](#input\_eks) | EKS cluster inputs | `any` | `{}` | no |
| <a name="input_external-dns"></a> [external-dns](#input\_external-dns) | Map of map for external-dns configuration: see `external_dns.tf` for supported values | `any` | `{}` | no |
| <a name="input_flux2"></a> [flux2](#input\_flux2) | Customize Flux chart, see `flux2.tf` for supported values | `any` | `{}` | no |
| <a name="input_helm_defaults"></a> [helm\_defaults](#input\_helm\_defaults) | Customize default Helm behavior | `any` | `{}` | no |
| <a name="input_ingress-nginx"></a> [ingress-nginx](#input\_ingress-nginx) | Customize ingress-nginx chart, see `nginx-ingress.tf` for supported values | `any` | `{}` | no |
| <a name="input_ip-masq-agent"></a> [ip-masq-agent](#input\_ip-masq-agent) | Configure ip masq agent chart, see `ip-masq-agent.tf` for supported values. This addon works only on GCP. | `any` | `{}` | no |
| <a name="input_k8gb"></a> [k8gb](#input\_k8gb) | Customize k8gb chart, see `k8gb.tf` for supported values | `any` | `{}` | no |
| <a name="input_karma"></a> [karma](#input\_karma) | Customize karma chart, see `karma.tf` for supported values | `any` | `{}` | no |
| <a name="input_karpenter"></a> [karpenter](#input\_karpenter) | Customize karpenter chart, see `karpenter.tf` for supported values | `any` | `{}` | no |
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
| <a name="input_prometheus-cloudwatch-exporter"></a> [prometheus-cloudwatch-exporter](#input\_prometheus-cloudwatch-exporter) | Customize prometheus-cloudwatch-exporter chart, see `prometheus-cloudwatch-exporter.tf` for supported values | `any` | `{}` | no |
| <a name="input_promtail"></a> [promtail](#input\_promtail) | Customize promtail chart, see `loki-stack.tf` for supported values | `any` | `{}` | no |
| <a name="input_s3-logging"></a> [s3-logging](#input\_s3-logging) | Logging configuration for bucket created by this module | `any` | `{}` | no |
| <a name="input_sealed-secrets"></a> [sealed-secrets](#input\_sealed-secrets) | Customize sealed-secrets chart, see `sealed-secrets.tf` for supported values | `any` | `{}` | no |
| <a name="input_secrets-store-csi-driver"></a> [secrets-store-csi-driver](#input\_secrets-store-csi-driver) | Customize secrets-store-csi-driver chart, see `secrets-store-csi-driver.tf` for supported values | `any` | `{}` | no |
| <a name="input_secrets-store-csi-driver-provider-aws"></a> [secrets-store-csi-driver-provider-aws](#input\_secrets-store-csi-driver-provider-aws) | Enable secrets-store-csi-driver-provider-aws | `any` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags for AWS resources | `map(any)` | `{}` | no |
| <a name="input_thanos"></a> [thanos](#input\_thanos) | Customize thanos chart, see `thanos.tf` for supported values | `any` | `{}` | no |
| <a name="input_thanos-memcached"></a> [thanos-memcached](#input\_thanos-memcached) | Customize thanos chart, see `thanos.tf` for supported values | `any` | `{}` | no |
| <a name="input_thanos-storegateway"></a> [thanos-storegateway](#input\_thanos-storegateway) | Customize thanos chart, see `thanos.tf` for supported values | `any` | `{}` | no |
| <a name="input_thanos-tls-querier"></a> [thanos-tls-querier](#input\_thanos-tls-querier) | Customize thanos chart, see `thanos.tf` for supported values | `any` | `{}` | no |
| <a name="input_tigera-operator"></a> [tigera-operator](#input\_tigera-operator) | Customize tigera-operator chart, see `tigera-operator.tf` for supported values | `any` | `{}` | no |
| <a name="input_traefik"></a> [traefik](#input\_traefik) | Customize traefik chart, see `traefik.tf` for supported values | `any` | `{}` | no |
| <a name="input_velero"></a> [velero](#input\_velero) | Customize velero chart, see `velero.tf` for supported values | `any` | `{}` | no |
| <a name="input_victoria-metrics-k8s-stack"></a> [victoria-metrics-k8s-stack](#input\_victoria-metrics-k8s-stack) | Customize Victoria Metrics chart, see `victoria-metrics-k8s-stack.tf` for supported values | `any` | `{}` | no |
| <a name="input_yet-another-cloudwatch-exporter"></a> [yet-another-cloudwatch-exporter](#input\_yet-another-cloudwatch-exporter) | Customize yet-another-cloudwatch-exporter chart, see `yet-another-cloudwatch-exporter.tf` for supported values | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_karpenter_iam"></a> [karpenter\_iam](#output\_karpenter\_iam) | n/a |
| <a name="output_kube-prometheus-stack"></a> [kube-prometheus-stack](#output\_kube-prometheus-stack) | n/a |
| <a name="output_kube-prometheus-stack_sensitive"></a> [kube-prometheus-stack\_sensitive](#output\_kube-prometheus-stack\_sensitive) | n/a |
| <a name="output_loki-stack-ca"></a> [loki-stack-ca](#output\_loki-stack-ca) | n/a |
| <a name="output_promtail-cert"></a> [promtail-cert](#output\_promtail-cert) | n/a |
| <a name="output_promtail-key"></a> [promtail-key](#output\_promtail-key) | n/a |
| <a name="output_thanos_ca"></a> [thanos\_ca](#output\_thanos\_ca) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
