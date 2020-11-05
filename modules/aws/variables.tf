variable "cluster-name" {
  description = "Name of the Kubernetes cluster"
  default     = "sample-cluster"
  type        = string
}
variable "aws" {
  description = "AWS provider customization"
  type        = any
  default     = {}
}

variable "eks" {
  description = "EKS cluster inputs"
  type        = any
  default     = {}
}

variable "nginx_ingress" {
  description = "Customize nginx-ingress chart, see `nginx-ingress.tf` for supported values"
  type        = any
  default     = {}
}

variable "cluster_autoscaler" {
  description = "Customize cluster-autoscaler chart, see `cluster_autoscaler.tf` for supported values"
  type        = any
  default     = {}
}

variable "external_dns" {
  description = "Customize external-dns chart, see `external_dns.tf` for supported values"
  type        = any
  default     = {}
}

variable "external_dns_secondary" {
  description = "Customize external-dns chart, see `external_dns_secondary.tf` for supported values"
  type        = any
  default     = {}
}

variable "cert_manager" {
  description = "Customize cert-manager chart, see `cert_manager.tf` for supported values"
  type        = any
  default     = {}
}

variable "kiam" {
  description = "Customize kiam chart, see `kiam.tf` for supported values"
  type        = any
  default     = {}
}

variable "metrics_server" {
  description = "Customize metrics-server chart, see `metrics_server.tf` for supported values"
  type        = any
  default     = {}
}

variable "prometheus_operator" {
  description = "Customize prometheus-operator chart, see `kube_prometheus.tf` for supported values"
  type        = any
  default     = {}
}

variable "fluentd_cloudwatch" {
  description = "Customize fluentd-cloudwatch chart, see `fluentd-cloudwatch.tf` for supported values"
  type        = any
  default     = {}
}

variable "npd" {
  description = "Customize node-problem-detector chart, see `npd.tf` for supported values"
  type        = any
  default     = {}
}

variable "flux" {
  description = "Customize fluxcd chart, see `flux.tf` for supported values"
  type        = any
  default     = {}
}

variable "sealed_secrets" {
  description = "Customize sealed-secrets chart, see `sealed-secrets.tf` for supported values"
  type        = any
  default     = {}
}


variable "cni_metrics_helper" {
  description = "Customize cni-metrics-helper deployment, see `cni_metrics_helper.tf` for supported values"
  type        = any
  default     = {}
}

variable "kong" {
  description = "Customize kong-ingress chart, see `kong.tf` for supported values"
  type        = any
  default     = {}
}

variable "keycloak" {
  description = "Customize keycloak chart, see `keycloak.tf` for supported values"
  type        = any
  default     = {}
}

variable "karma" {
  description = "Customize karma chart, see `karma.tf` for supported values"
  type        = any
  default     = {}
}

variable "istio_operator" {
  description = "Customize istio operator deployment, see `istio_operator.tf` for supported values"
  type        = any
  default     = {}
}

variable "alb_ingress" {
  description = "Customize alb-ingress chart, see `alb-ingress.tf` for supported values"
  type        = any
  default     = {}
}

variable "aws_node_termination_handler" {
  description = "Customize aws-node-termination-handler chart, see `aws-node-termination-handler.tf`"
  type        = any
  default     = {}
}

variable "calico" {
  description = "Customize calico helm chart, see `calico.tf`"
  type        = any
  default     = {}
}

variable "aws_fluent_bit" {
  description = "Customize aws-for-fluent-bit helm chart, see `aws_fluent_bit.tf`"
  type        = any
  default     = {}
}

variable "helm_defaults" {
  description = "Customize default Helm behavior"
  type        = any
  default     = {}
}

variable "priority_class" {
  description = "Customize a priority class for addons"
  type        = any
  default     = {}
}

variable "priority_class_ds" {
  description = "Customize a priority class for addons daemonsets"
  type        = any
  default     = {}
}
