variable "google" {
  description = "GCP provider customization"
  type        = any
  default     = {}
}

variable "project_id" {
  description = "GCP project id"
  type        = string
  default     = ""
}

variable "cni-metrics-helper" {
  description = "Customize cni-metrics-helper deployment, see `cni-metrics-helper.tf` for supported values"
  type        = any
  default     = {}
}

variable "gke" {
  description = "GKE cluster inputs"
  type        = any
  default     = {}
}

variable "prometheus-cloudwatch-exporter" {
  description = "Customize prometheus-cloudwatch-exporter chart, see `prometheus-cloudwatch-exporter.tf` for supported values"
  type        = any
  default     = {}
}

variable "tags" {
  description = "Map of tags for Google resources"
  type        = map(any)
  default     = {}
}

variable "velero" {
  description = "Customize velero chart, see `velero.tf` for supported values"
  type        = any
  default     = {}
}
