# terraform-kubernetes-addons

[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/terraform-kubernetes-addons)
[![terraform-kubernetes-addons](https://github.com/particuleio/terraform-kubernetes-addons/workflows/terraform-kubernetes-addons/badge.svg)](https://github.com/particuleio/terraform-kubernetes-addons/actions?query=workflow%3Aterraform-kubernetes-addons)

## Main components

| Name                                                                                                                          | Description                                                                                      | Generic             | AWS                 | Scaleway            | GCP                 | Azure               |
|------|-------------|:-------:|:---:|:--------:|:---:|:-----:|
| [admiralty](https://admiralty.io/)                                                                                            | A system of Kubernetes controllers that intelligently schedules workloads across clusters        | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  |
| [aws-ebs-csi-driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver)                                                   | Enable new feature and the use of `gp3` volumes                                                  | N/A                 | :heavy_check_mark:  | N/A                 | N/A                 | N/A                 |
| [aws-efs-csi-driver](https://github.com/kubernetes-sigs/aws-efs-csi-driver)                                                   | Enable EFS Support                                                                               | N/A                 | :heavy_check_mark:  | N/A                 | N/A                 | N/A                 |
| [aws-for-fluent-bit](https://github.com/aws/aws-for-fluent-bit)                                                               | Cloudwatch logging with fluent bit instead of fluentd                                            | N/A                 | :heavy_check_mark:  | N/A                 | N/A                 | N/A                 |
| [aws-load-balancer-controller](https://aws.amazon.com/about-aws/whats-new/2020/10/introducing-aws-load-balancer-controller/)  | Use AWS ALB/NLB for ingress and services                                                         | N/A                 | :heavy_check_mark:  | N/A                 | N/A                 | N/A                 |
| [aws-node-termination-handler](https://github.com/aws/aws-node-termination-handler)                                           | Manage spot instance lifecyle                                                                    | N/A                 | :heavy_check_mark:  | N/A                 | N/A                 | N/A                 |
| [aws-calico](https://github.com/aws/eks-charts/tree/master/stable/aws-calico)                                                 | Use calico for network policy                                                                    | N/A                 | :heavy_check_mark:  | N/A                 | N/A                 | N/A                 |
| [secrets-store-csi-driver-provider-aws](https://github.com/aws/secrets-store-csi-driver-provider-aws) | AWS Secret Store and Parameter store driver for secret store CSI driver | :heavy_check_mark:  | N/A  | N/A  | N/A  | N/A  |
| [cert-manager](https://github.com/jetstack/cert-manager)                                                                      | automatically generate TLS certificates, supports ACME v2                                        | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :x:                 | N/A                 |
| [cluster-autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)                                 | scale worker nodes based on workload                                                             | N/A                 | :heavy_check_mark:  | Included            | Included            | Included            |
| [cni-metrics-helper](https://docs.aws.amazon.com/eks/latest/userguide/cni-metrics-helper.html)                                | Provides cloudwatch metrics for VPC CNI plugins                                                  | N/A                 | :heavy_check_mark:  | N/A                 | N/A                 | N/A                 |
| [external-dns](https://github.com/kubernetes-incubator/external-dns)                                                          | sync ingress and service records in route53                                                      | :x:                 | :heavy_check_mark:  | :heavy_check_mark:  | :x:                 | :x:                 |
| [flux2](https://github.com/fluxcd/flux2)                                                                                      | Open and extensible continuous delivery solution for Kubernetes. Powered by GitOps Toolkit       | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  |
| [ingress-nginx](https://github.com/kubernetes/ingress-nginx)                                                                  | processes `Ingress` object and acts as a HTTP/HTTPS proxy (compatible with cert-manager)         | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :x:                 | :x:                 |
| [k8gb](https://www.k8gb.io/)                                                                                                  | A cloud native Kubernetes Global Balancer                                                        | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  |
| [karma](https://github.com/prymitive/karma)                                                                                   | An alertmanager dashboard                                                                        | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  |
| [keda](https://github.com/kedacore/keda)                                                                                      | Kubernetes Event-driven Autoscaling                                                              | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  |
| [kong](https://konghq.com/kong)                                                                                               | API Gateway ingress controller                                                                   | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :x:                 | :x:                 |
| [kube-prometheus-stack](https://github.com/prometheus-operator/kube-prometheus)                                               | Monitoring / Alerting / Dashboards                                                               | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :x:                 | :x:                 |
| [loki-stack](https://grafana.com/oss/loki/)                                                                                   | Grafana Loki logging stack                                                                       | :heavy_check_mark:  | :heavy_check_mark:  | :construction:      | :x:                 | :x:                 |
| [promtail](https://grafana.com/docs/loki/latest/clients/promtail/)                                                            | Ship log to loki from other cluster (eg. mTLS)                                                   | :construction:      | :heavy_check_mark:  | :construction:      | :x:                 | :x:                 |
| [prometheus-adapter](https://github.com/kubernetes-sigs/prometheus-adapter)                                                   | Prometheus metrics for use with the autoscaling/v2 Horizontal Pod Autoscaler in Kubernetes 1.6+  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  |
| [prometheus-cloudwatch-exporter](https://github.com/prometheus/cloudwatch_exporter)                                           | An exporter for Amazon CloudWatch, for Prometheus.                                               | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  |
| [prometheus-blackbox-exporter](https://github.com/prometheus/blackbox_exporter)                                               | The blackbox exporter allows blackbox probing of endpoints over HTTP, HTTPS, DNS, TCP and ICMP.  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  |
| [rabbitmq-cluster-operator](https://github.com/rabbitmq/cluster-operator)                                                     | The RabbitMQ Cluster Operator automates provisioning, management of RabbitMQ clusters.           | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  |
| [metrics-server](https://github.com/kubernetes-incubator/metrics-server)                                                      | enable metrics API and horizontal pod scaling (HPA)                                              | :heavy_check_mark:  | :heavy_check_mark:  | Included            | Included            | Included            |
| [node-problem-detector](https://github.com/kubernetes/node-problem-detector)                                                  | Forwards node problems to Kubernetes events                                                      | :heavy_check_mark:  | :heavy_check_mark:  | Included            | Included            | Included            |
| [secrets-store-csi-driver](https://github.com/kubernetes-sigs/secrets-store-csi-driver) | Secrets Store CSI driver for Kubernetes secrets - Integrates secrets stores with Kubernetes via a CSI volume. | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  |
| [sealed-secrets](https://github.com/bitnami-labs/sealed-secrets)                                                              | Technology agnostic, store secrets on git                                                        | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark:  |
| [thanos](https://thanos.io/)                                                                                                  | Open source, highly available Prometheus setup with long term storage capabilities               | :x:                 | :heavy_check_mark:  | :construction:      | :x:                 | :x:                 |
| [thanos-memcached](https://thanos.io/tip/components/query-frontend.md/#memcached)                                             | Open source, highly available Prometheus setup with long term storage capabilities               | :x:                 | :heavy_check_mark:  | :construction:      | :x:                 | :x:                 |
| [thanos-storegateway](https://thanos.io/)                                                                                     | Additional storegateway to query multiple object stores                                          | :x:                 | :heavy_check_mark:  | :construction:      | :x:                 | :x:                 |
| [thanos-tls-querier](https://thanos.io/tip/operating/cross-cluster-tls-communication.md/)                                     | Thanos TLS querier for cross cluster collection                                                  | :x:                 | :heavy_check_mark:  | :construction:      | :x:                 | :x:                 |

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

## Contributing

Report issues/questions/feature requests on in the
[issues](https://github.com/particuleio/terraform-kubernetes-addons/issues/new)
section.

Full contributing [guidelines are covered
here](https://github.com/particuleio/terraform-kubernetes-addons/blob/master/.github/CONTRIBUTING.md).

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
| [helm_release.metrics-server](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.node-problem-detector](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.prometheus-adapter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.prometheus-blackbox-exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.promtail](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.sealed-secrets](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.secrets-store-csi-driver](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.tigera-operator](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.traefik](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.victoria-metrics-k8s-stack](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.calico_crds](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.cert-manager_cluster_issuers](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.csi-external-snapshotter](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.kong_crds](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.linkerd](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.linkerd-viz](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.prometheus-operator_crds](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.tigera-operator_crds](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_config_map.loki-stack_grafana_ds](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_namespace.admiralty](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.cert-manager](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
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
| [kubernetes_namespace.metrics-server](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.node-problem-detector](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.prometheus-adapter](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.prometheus-blackbox-exporter](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.promtail](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.sealed-secrets](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.secrets-store-csi-driver](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.tigera-operator](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.traefik](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.victoria-metrics-k8s-stack](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_network_policy.admiralty_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.admiralty_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.cert-manager_allow_control_plane](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.cert-manager_allow_monitoring](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.cert-manager_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.cert-manager_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
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
| [kubernetes_network_policy.metrics-server_allow_control_plane](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.metrics-server_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.metrics-server_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.npd_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.npd_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.prometheus-adapter_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.prometheus-adapter_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.prometheus-blackbox-exporter_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.prometheus-blackbox-exporter_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
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
| [kubernetes_network_policy.victoria-metrics-k8s-stack_allow_control_plane](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.victoria-metrics-k8s-stack_allow_ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.victoria-metrics-k8s-stack_allow_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_network_policy.victoria-metrics-k8s-stack_default_deny](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_priority_class.kubernetes_addons](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/priority_class) | resource |
| [kubernetes_priority_class.kubernetes_addons_ds](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/priority_class) | resource |
| [kubernetes_secret.linkerd_trust_anchor](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.loki-stack-ca](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.promtail-tls](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.webhook_issuer_tls](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [random_string.grafana_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [time_sleep.cert-manager_sleep](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [tls_cert_request.promtail-csr](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/cert_request) | resource |
| [tls_locally_signed_cert.promtail-cert](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/locally_signed_cert) | resource |
| [tls_private_key.identity](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.linkerd_trust_anchor](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.loki-stack-ca-key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.promtail-key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.webhook_issuer_tls](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_self_signed_cert.linkerd_trust_anchor](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
| [tls_self_signed_cert.loki-stack-ca-cert](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
| [tls_self_signed_cert.webhook_issuer_tls](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
| [github_repository.main](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/repository) | data source |
| [http_http.calico_crds](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.csi-external-snapshotter](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.kong_crds](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.prometheus-operator_crds](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.prometheus-operator_version](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.tigera-operator_crds](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [kubectl_file_documents.calico_crds](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/file_documents) | data source |
| [kubectl_file_documents.csi-external-snapshotter](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/file_documents) | data source |
| [kubectl_file_documents.kong_crds](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/file_documents) | data source |
| [kubectl_file_documents.tigera-operator_crds](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/file_documents) | data source |
| [kubectl_path_documents.cert-manager_cluster_issuers](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/path_documents) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admiralty"></a> [admiralty](#input\_admiralty) | Customize admiralty chart, see `admiralty.tf` for supported values | `any` | `{}` | no |
| <a name="input_cert-manager"></a> [cert-manager](#input\_cert-manager) | Customize cert-manager chart, see `cert-manager.tf` for supported values | `any` | `{}` | no |
| <a name="input_cert-manager-csi-driver"></a> [cert-manager-csi-driver](#input\_cert-manager-csi-driver) | Customize cert-manager-csi-driver chart, see `cert-manager.tf` for supported values | `any` | `{}` | no |
| <a name="input_cluster-autoscaler"></a> [cluster-autoscaler](#input\_cluster-autoscaler) | Customize cluster-autoscaler chart, see `cluster-autoscaler.tf` for supported values | `any` | `{}` | no |
| <a name="input_cluster-name"></a> [cluster-name](#input\_cluster-name) | Name of the Kubernetes cluster | `string` | `"sample-cluster"` | no |
| <a name="input_csi-external-snapshotter"></a> [csi-external-snapshotter](#input\_csi-external-snapshotter) | Customize csi-external-snapshotter, see `csi-external-snapshotter.tf` for supported values | `any` | `{}` | no |
| <a name="input_external-dns"></a> [external-dns](#input\_external-dns) | Map of map for external-dns configuration: see `external_dns.tf` for supported values | `any` | `{}` | no |
| <a name="input_flux2"></a> [flux2](#input\_flux2) | Customize Flux chart, see `flux2.tf` for supported values | `any` | `{}` | no |
| <a name="input_helm_defaults"></a> [helm\_defaults](#input\_helm\_defaults) | Customize default Helm behavior | `any` | `{}` | no |
| <a name="input_ingress-nginx"></a> [ingress-nginx](#input\_ingress-nginx) | Customize ingress-nginx chart, see `nginx-ingress.tf` for supported values | `any` | `{}` | no |
| <a name="input_ip-masq-agent"></a> [ip-masq-agent](#input\_ip-masq-agent) | Configure ip masq agent chart, see `ip-masq-agent.tf` for supported values. This addon works only on GCP. | `any` | `{}` | no |
| <a name="input_k8gb"></a> [k8gb](#input\_k8gb) | Customize k8gb chart, see `k8gb.tf` for supported values | `any` | `{}` | no |
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
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
