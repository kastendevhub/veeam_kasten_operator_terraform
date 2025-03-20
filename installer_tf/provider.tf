terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.90.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.13.0"
    }
    rhcs = {
      source  = "terraform-redhat/rhcs"
      version = "1.6.8"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.36.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}

provider "rhcs" {
  token = var.token
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

# Kubernetes provider with longer timeout for CRD-dependent resources
provider "kubernetes" {
  alias       = "longer_timeout"
  config_path = "~/.kube/config"
}

# Add kubectl provider configuration
provider "kubectl" {
  config_path       = var.kubeconfig_path
  apply_retry_count = 5
}