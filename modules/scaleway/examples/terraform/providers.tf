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

provider "kubernetes" {
  host                   = module.kapsule.kubeconfig[0]["host"]
  cluster_ca_certificate = base64decode(module.kapsule.kubeconfig[0]["cluster_ca_certificate"])
  token                  = module.kapsule.kubeconfig[0]["token"]
}

provider "helm" {
  kubernetes {
    host                   = module.kapsule.kubeconfig[0]["host"]
    cluster_ca_certificate = base64decode(module.kapsule.kubeconfig[0]["cluster_ca_certificate"])
    token                  = module.kapsule.kubeconfig[0]["token"]
  }
}

provider "kubectl" {
  host                   = module.kapsule.kubeconfig[0]["host"]
  cluster_ca_certificate = base64decode(module.kapsule.kubeconfig[0]["cluster_ca_certificate"])
  token                  = module.kapsule.kubeconfig[0]["token"]
  load_config_file       = false
}
