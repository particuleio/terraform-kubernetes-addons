variable "arn-partition" {
  description = "ARN partition"
  default     = ""
  type        = string
}

variable "aws" {
  description = "AWS provider customization"
  type        = any
  default     = {}
}

variable "aws-ebs-csi-driver" {
  description = "Customize aws-ebs-csi-driver helm chart, see `aws-ebs-csi-driver.tf`"
  type        = any
  default     = {}
}

variable "aws-efs-csi-driver" {
  description = "Customize aws-efs-csi-driver helm chart, see `aws-efs-csi-driver.tf`"
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

variable "cni-metrics-helper" {
  description = "Customize cni-metrics-helper deployment, see `cni-metrics-helper.tf` for supported values"
  type        = any
  default     = {}
}

variable "eks" {
  description = "EKS cluster inputs"
  type        = any
  default     = {}
}

variable "karpenter" {
  description = "Customize karpenter chart, see `karpenter.tf` for supported values"
  type        = any
  default     = {}
}

variable "prometheus-cloudwatch-exporter" {
  description = "Customize prometheus-cloudwatch-exporter chart, see `prometheus-cloudwatch-exporter.tf` for supported values"
  type        = any
  default     = {}
}

variable "s3-logging" {
  description = "Logging configuration for bucket created by this module"
  type        = any
  default     = {}
}

variable "secrets-store-csi-driver-provider-aws" {
  description = "Enable secrets-store-csi-driver-provider-aws"
  type        = any
  default     = {}
}

variable "tags" {
  description = "Map of tags for AWS resources"
  type        = map(any)
  default     = {}
}

variable "yet-another-cloudwatch-exporter" {
  description = "Customize yet-another-cloudwatch-exporter chart, see `yet-another-cloudwatch-exporter.tf` for supported values"
  type        = any
  default     = {}
}
