###################################################################
//Variables for ROSA Cluster credentials
###################################################################

variable "kubeconfig_path" {
  description = "The path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "token" {
  type        = string
  description = "OpenShift Cluster Manager API Token"
}

###################################################################
//Variables for Veeam Kasten installtion
###################################################################
variable "kasten_ocp_project_description" {
  description = "The description of the Kasten K10 project"
  type        = string
  default     = "Kubernetes data management platform"
  
}

variable "kasten_ocp_project_display_name" {
  description = "The description of the Kasten K10 project"
  type        = string
  default     = "Kasten K10"
  
}

variable "kasten_namespace" {
  description = "The namespace for the Kasten K10 installation"
  type        = string
  default     = "kasten-io"
}

variable "channel" {
  description = "The channel for the Kasten K10 installation"
  type        = string
}

variable "installPlanApproval" {
  description = "The install plan approval for the Veeam Kasten Operator"
  type        = string
}

variable "kasten_operator_name" {
  description = "Name of the Veeam Kasten Operator"
  type        = string
}

variable "source_catalog" {
  description = "Source of the catalog for the Veeam Kasten Operator"
  type        = string
}

variable "sourceNamespace" {
  description = "Namespace of the catalog for the Veeam Kasten Operator"
  type        = string
}

variable "startingCSV" {
  description = "The starting CSV for the Kasten K10 installation"
  type        = string
  
}

###################################################################
//Variables for OpenShift Virtualization
###################################################################
variable "enable_openshift_virtualization" {
  description = "Whether to enable OpenShift Virtualization"
  type        = bool
  default     = false
}

###################################################################
//Variables for OpenShift Advanced Cluster Management (ACM)
###################################################################
variable "enable_advanced_cluster_management" {
  description = "Whether to enable OpenShift Advanced Cluster Management"
  type        = bool
  default     = false
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
    error_message = "The name of the environment variable must end with '-tf'."
  }
}

