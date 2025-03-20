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
}

variable "kasten_namespace" {
  description = "The namespace for the Kasten K10 installation"
  type        = string
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

