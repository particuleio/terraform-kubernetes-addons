terraform {
  required_version = ">= 0.13"
  required_providers {
    helm       = "~> 2.0"
    kubernetes = "~> 2.0, != 2.12"
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "<= 0.17"
    }
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
    skopeo = {
      source  = "abergmeier/skopeo"
      version = "0.0.4"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
