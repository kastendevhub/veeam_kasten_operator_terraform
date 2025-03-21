############################################################################################
// OpenShift Virtualization Module
############################################################################################

module "openshift_virtualization" {
  source = "../../catalog/ocp_ocpv"
  
  enable_openshift_virtualization = var.enable_openshift_virtualization
}

############################################################################################
// OpenShift Advanced Cluster Management (ACM) Module
############################################################################################

module "openshift_acm" {
  source = "../../catalog/ocp_acm"
  
 enable_advanced_cluster_management = var.enable_advanced_cluster_management
}