terraform {
  required_version = ">= 1.3.2"
  required_providers {
    helm       = "~> 3.0"
    kubernetes = "~> 2.0, != 2.12"
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "~> 1.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3"
    }
  }
}
