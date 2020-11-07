terraform {
  backend "s3" {
    bucket                      = "kapsule-cluster-prod"
    key                         = "kapsule-cluster-prod"
    region                      = "fr-par"
    endpoint                    = "https://s3.fr-par.scw.cloud"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

provider "scaleway" {
  region          = var.scaleway["region"]
  zone            = var.scaleway["fr-par-1"]
  access_key      = var.scaleway["access_key"]
  secret_key      = var.scaleway["secret_key"]
  organization_id = var.scaleway["organization_id"]
}

provider "kubernetes" {
  host                   = module.kapsule.kubeconfig[0]["host"]
  cluster_ca_certificate = base64decode(module.kapsule.kubeconfig[0]["cluster_ca_certificate"])
  token                  = module.kapsule.kubeconfig[0]["token"]
  load_config_file       = false
}

provider "helm" {
  version = "~> 1.0"
  kubernetes {
    host                   = module.kapsule.kubeconfig[0]["host"]
    cluster_ca_certificate = base64decode(module.kapsule.kubeconfig[0]["cluster_ca_certificate"])
    token                  = module.kapsule.kubeconfig[0]["token"]
    load_config_file       = false
  }
}

provider "kubectl" {
  host                   = module.kapsule.kubeconfig[0]["host"]
  cluster_ca_certificate = base64decode(module.kapsule.kubeconfig[0]["cluster_ca_certificate"])
  token                  = module.kapsule.kubeconfig[0]["token"]
  load_config_file       = false
}
