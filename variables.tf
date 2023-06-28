variable "admiralty" {
  description = "Customize admiralty chart, see `admiralty.tf` for supported values"
  type        = any
  default     = {}
}

variable "cert-manager" {
  description = "Customize cert-manager chart, see `cert-manager.tf` for supported values"
  type        = any
  default     = {}
}

variable "cert-manager-csi-driver" {
  description = "Customize cert-manager-csi-driver chart, see `cert-manager.tf` for supported values"
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

variable "csi-external-snapshotter" {
  description = "Customize csi-external-snapshotter, see `csi-external-snapshotter.tf` for supported values"
  type        = any
  default     = {}
}

variable "external-dns" {
  description = "Map of map for external-dns configuration: see `external_dns.tf` for supported values"
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

variable "k8gb" {
  description = "Customize k8gb chart, see `k8gb.tf` for supported values"
  type        = any
  default     = {}
}

variable "karma" {
  description = "Customize karma chart, see `karma.tf` for supported values"
  type        = any
  default     = {}
}

variable "keda" {
  description = "Customize keda chart, see `keda.tf` for supported values"
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

variable "linkerd2" {
  description = "Customize linkerd2 chart, see `linkerd2.tf` for supported values"
  type        = any
  default     = {}
}

variable "linkerd2-cni" {
  description = "Customize linkerd2-cni chart, see `linkerd2-cni.tf` for supported values"
  type        = any
  default     = {}
}

variable "linkerd-viz" {
  description = "Customize linkerd-viz chart, see `linkerd-viz.tf` for supported values"
  type        = any
  default     = {}
}

variable "linkerd" {
  description = "Customize linkerd chart, see `linkerd.tf` for supported values"
  type        = any
  default     = {}
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

variable "prometheus-blackbox-exporter" {
  description = "Customize prometheus-blackbox-exporter chart, see `prometheus-blackbox-exporter.tf` for supported values"
  type        = any
  default     = {}
}

variable "prometheus-adapter" {
  description = "Customize prometheus-adapter chart, see `prometheus-adapter.tf` for supported values"
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

variable "secrets-store-csi-driver" {
  description = "Customize secrets-store-csi-driver chart, see `secrets-store-csi-driver.tf` for supported values"
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

variable "tigera-operator" {
  description = "Customize tigera-operator chart, see `tigera-operator.tf` for supported values"
  type        = any
  default     = {}
}

variable "traefik" {
  description = "Customize traefik chart, see `traefik.tf` for supported values"
  type        = any
  default     = {}
}

variable "victoria-metrics-k8s-stack" {
  description = "Customize Victoria Metrics chart, see `victoria-metrics-k8s-stack.tf` for supported values"
  type        = any
  default     = {}
}

variable "ip-masq-agent" {
  description = "Configure ip masq agent chart, see `ip-masq-agent.tf` for supported values. This addon works only on GCP."
  type        = any
  default     = {}
}
