############################################################################################
//Variables for AWS Provider
############################################################################################

variable "aws_region" {
  description = "The AWS region to use"
  type        = string

}

############################################################################################
//Variables for AWS VPC
############################################################################################

//Networking variables
variable "new_vpc_cidr" {
  description = "The CIDR block for the new VPC"
  type        = string
  default     = "10.0.0.0/19"
}

variable "new_vpc_name" {
  description = "The name of the new VPC"
  type        = string

  validation {
    condition     = can(regex(".*-tf$", var.new_vpc_name))
    error_message = "The name of the vpc variable must end with '-tf'."
  }
}

############################################################################################
//Variables for AWS Internet Gateway ROSA
############################################################################################

variable "rosa_gateway_name" {
  description = "The name of the Internet Gateway for ROSA"
  type        = string
  default     = "rosa-gateway"

}

############################################################################################
//Variables for AWS ROSA Public Subnet
############################################################################################

variable "public_subnet_name" {
  description = "The name of the public subnet"
  type        = string
  default     = "public-subnet-1-tf"

}

variable "public_subnet_cidr" {
  description = "The CIDR blocks for the public subnets"
  type        = string
  default     = "10.0.0.0/22"
}

############################################################################################
//Variables for AWS ROSA Private Subnet
############################################################################################

variable "private_subnet_name" {
  description = "The name of the private subnet"
  type        = string
  default     = "private-subnet-1-tf"
}

variable "private_subnet_cidr" {
  description = "The CIDR blocks for the private subnets"
  type        = string
  default     = "10.0.12.0/22"
}

############################################################################################
//Variables ROSA Cluster
############################################################################################

variable "cluster_name" {
  type        = string
  description = "Name of the ROSA cluster. After the creation of the resource, it is not possible to update the attribute value."

  validation {
    condition     = can(regex(".*-tf$", var.cluster_name))
    error_message = "The name of the bucket variable must end with '-tf'."
  }
}

variable "openshift_version" {
  type        = string
  description = "The required version of Red Hat OpenShift for the cluster"

  validation {
    condition     = can(regex("^[0-9]*[0-9]+.[0-9]*[0-9]+.[0-9]*[0-9]+$", var.openshift_version))
    error_message = "openshift_version must be with structure <major>.<minor>.<patch> (for example 4.13.6)."
  }
}

variable "token" {
  type        = string
  description = "OpenShift Cluster Manager API Token"
}

variable "compute_machine_type" {
  description = "The AWS instance type for the compute nodes"
  type        = string
  }

variable "htpasswd_idp_user" {
  type        = string
  description = "Name of the local user for OCP authentication"

}

variable "htpasswd" {
  type        = string
  description = "value of the htpasswd"
}

############################################################################################
//Variables Tags for resources managed by Terraform
############################################################################################

variable "tag_expire_by" {
  type        = string
  description = "Date of expiration"
  default     = "2024-08-01"

  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.tag_expire_by))
    error_message = "The tag_expire_by variable must be in the format YYYY-MM-DD."
  }
}

variable "tag_environment" {
  type        = string
  description = "Name of the environement"
  default     = "project-xyz-tf"

  validation {
    condition     = can(regex(".*-tf$", var.tag_environment))
    error_message = "The name of the bucket variable must end with '-tf'."
  }
}

############################################################################################
//Variables AWS S3 Bucket for ROSA
############################################################################################

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"

  validation {
    condition     = can(regex(".*-tf$", var.bucket_name))
    error_message = "The name of the bucket variable must end with '-tf'."
  }
}

variable "acl" {
  type    = string
  default = "private"
}

############################################################################################
//End of variables.tf
############################################################################################