variable "scaleway" {
  description = "Scaleway provider customization"
  type        = any
  default     = {}
}

variable "kapsule" {
  description = "Kapsule cluster inputs"
  type        = any
  default     = {}
}

variable "cert-manager_scaleway_webhook_dns" {
  description = "Scaleway webhook dns customization"
  type        = any
  default     = {}
}
