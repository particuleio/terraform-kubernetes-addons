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

variable "cluster-name" {
  description = "Name of the Kubernetes cluster"
  default     = "sample-cluster"
  type        = string
}

variable "cortex" {
  description = "Customize thanos chart, see `cortex.tf` for supported values"
  type        = any
  default     = {}
}

variable "external-dns" {
  description = "Map of map for external-dns configuration: see `external_dns.tf` for supported values"
  type        = any
  default     = {}
}

variable "flux" {
  description = "Customize Flux chart, see `flux.tf` for supported values"
  type        = any
  default     = {}
}

variable "flux2" {
  description = "Customize Flux chart, see `flux2.tf` for supported values"
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

variable "kyverno" {
  description = "Customize kyverno chart, see `kyverno.tf` for supported values"
  type        = any
  default     = {}
}

variable "labels_prefix" {
  description = "Custom label prefix used for network policy namespace matching"
  type        = string
  default     = "particule.io"
}

variable "loki-stack" {
  description = "Customize loki-stack chart, see `loki-stack.tf` for supported values"
  type        = any
  default     = {}
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

variable "promtail" {
  description = "Customize promtail chart, see `loki-stack.tf` for supported values"
  type        = any
  default     = {}
}

variable "sealed-secrets" {
  description = "Customize sealed-secrets chart, see `sealed-secrets.tf` for supported values"
  type        = any
  default     = {}
}

variable "strimzi-kafka-operator" {
  description = "Customize strimzi-kafka-operator chart, see `strimzi-kafka-operator.tf` for supported values"
  type        = any
  default     = {}
}

variable "thanos" {
  description = "Customize thanos chart, see `thanos.tf` for supported values"
  type        = any
  default     = {}
}

variable "thanos-tls-querier" {
  description = "Customize thanos chart, see `thanos.tf` for supported values"
  type        = any
  default     = {}
}

variable "thanos-storegateway" {
  description = "Customize thanos chart, see `thanos.tf` for supported values"
  type        = any
  default     = {}
}

variable "thanos-memcached" {
  description = "Customize thanos chart, see `thanos.tf` for supported values"
  type        = any
  default     = {}
}