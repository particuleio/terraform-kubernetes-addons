variable "aws" {
  description = "AWS provider customization"
  type        = any
  default     = {}
}

variable "aws-for-fluent-bit" {
  description = "Customize aws-for-fluent-bit helm chart, see `aws-fluent-bit.tf`"
  type        = any
  default     = {}
}

variable "aws-load-balancer-controller" {
  description = "Customize aws-load-balancer-controller chart, see `aws-load-balancer-controller.tf` for supported values"
  type        = any
  default     = {}
}

variable "aws-node-termination-handler" {
  description = "Customize aws-node-termination-handler chart, see `aws-node-termination-handler.tf`"
  type        = any
  default     = {}
}

variable "calico" {
  description = "Customize calico helm chart, see `calico.tf`"
  type        = any
  default     = {}
}

variable "cert-manager" {
  description = "Customize cert-manager chart, see `cert-manager.tf` for supported values"
  type        = any
  default     = {}
}

variable "cluster-autoscaler" {
  description = "Customize cluster-autoscaler chart, see `cluster-autoscaler.tf` for supported values"
  type        = any
  default     = {}
}

variable "cni-metrics-helper" {
  description = "Customize cni-metrics-helper deployment, see `cni-metrics-helper.tf` for supported values"
  type        = any
  default     = {}
}

variable "cluster-name" {
  description = "Name of the Kubernetes cluster"
  default     = "sample-cluster"
  type        = string
}

variable "eks" {
  description = "EKS cluster inputs"
  type        = any
  default     = {}
}

variable "external-dns" {
  description = "Customize external-dns chart, see `external_dns.tf` for supported values"
  type        = any
  default     = {}
}

variable "helm_defaults" {
  description = "Customize default Helm behavior"
  type        = any
  default     = {}
}

variable "istio-operator" {
  description = "Customize istio operator deployment, see `istio_operator.tf` for supported values"
  type        = any
  default     = {}
}

variable "karma" {
  description = "Customize karma chart, see `karma.tf` for supported values"
  type        = any
  default     = {}
}

variable "keycloak" {
  description = "Customize keycloak chart, see `keycloak.tf` for supported values"
  type        = any
  default     = {}
}

variable "kong" {
  description = "Customize kong-ingress chart, see `kong.tf` for supported values"
  type        = any
  default     = {}
}

variable "kube-prometheus-stack" {
  description = "Customize kube-prometheus-stack chart, see `kube-prometheus-stack.tf` for supported values"
  type        = any
  default     = {}
}

variable "labels_prefix" {
  description = "Custom label prefix used for network policy namespace matching"
  type        = string
  default     = "particule.io"
}

variable "metrics-server" {
  description = "Customize metrics-server chart, see `metrics_server.tf` for supported values"
  type        = any
  default     = {}
}

variable "ingress-nginx" {
  description = "Customize ingress-nginx chart, see `nginx-ingress.tf` for supported values"
  type        = any
  default     = {}
}

variable "npd" {
  description = "Customize node-problem-detector chart, see `npd.tf` for supported values"
  type        = any
  default     = {}
}

variable "priority-class" {
  description = "Customize a priority class for addons"
  type        = any
  default     = {}
}

variable "priority-class-ds" {
  description = "Customize a priority class for addons daemonsets"
  type        = any
  default     = {}
}

variable "sealed-secrets" {
  description = "Customize sealed-secrets chart, see `sealed-secrets.tf` for supported values"
  type        = any
  default     = {}
}
