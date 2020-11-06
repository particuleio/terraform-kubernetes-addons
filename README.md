# terraform-kubernetes-addons

[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/terraform-kubernetes-addons)
[![terraform:aws](https://github.com/particuleio/terraform-kubernetes-addons/workflows/terraform:aws/badge.svg)](https://github.com/particuleio/terraform-kubernetes-addons/actions?query=workflow%3Aterraform:aws)

## Submodules

Submodules are used for specific cloud provider configuration such as IAM role for
AWS. For a Kubernetes vanilla cluster, generic addons should be used.

Any contribution supporting a new cloud provider is welcomed.

* [AWS](./modules/aws)
* [Scaleway](./modules/scaleway)
