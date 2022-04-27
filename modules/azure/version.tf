terraform {
  required_version = ">= 0.13"
  required_providers {
    azurerm    = ">= 2.0.0"
    helm       = "~> 2.0"
    kubernetes = "~> 2.0"
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "<= 0.13"
    }
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }
}


