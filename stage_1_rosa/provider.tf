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
  }
}

provider "aws" {
  default_tags {
    tags = {
      "tag_expire_by"   = var.tag_expire_by
      "tag_environment" = var.tag_environment
    }
  }
}

provider "rhcs" {
  token = var.token
}