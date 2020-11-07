terraform {
  required_version = ">= 0.13"
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = ">= 1.17.0"
    }
    helm       = "~> 1.0"
    kubernetes = "~> 1.0"
  }
}
