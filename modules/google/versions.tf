terraform {
  required_version = ">= 1.0"
  required_providers {
    google      = ">= 4.69"
    google-beta = ">= 4.69"
    helm        = "~> 2.0"
    kubernetes  = "~> 2.0, != 2.12"
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.0"
    }
    jinja = {
      source  = "NikolaLohinski/jinja"
      version = "~> 1.15"
    }
  }
}
