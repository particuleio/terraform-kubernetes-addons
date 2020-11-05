terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = ">= 2.55.0"
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.6.2"
    }
  }
}
