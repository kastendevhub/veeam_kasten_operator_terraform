###################################################################
//Variables for ROSA Cluster credentials
###################################################################
kubeconfig_path = "~/.kube/config"
token           = "vaue" //provision a ROSA cluster through the rhcs Terraform provider, an offline token access needs to be created by using the Red Hat Hybrid Cloud Console.
//https://console.redhat.com/openshift/token/rosa
###################################################################
//Variables for Veeam Kasten installation
###################################################################
kasten_ocp_project_description  = "Kubernetes data management platform"
kasten_ocp_project_display_name = "Kasten K10"
kasten_namespace                = "kasten-io"
channel                         = "stable"
installPlanApproval             = "Automatic"
kasten_operator_name            = "k10-kasten-operator-term-rhmp"
source_catalog                  = "redhat-marketplace"
sourceNamespace                 = "openshift-marketplace"
startingCSV                     = "k10-kasten-operator-term-rhmp.v7.5.7" //change the version of the Kasten K10 operator if needed

############################################################################################
// Module for ROSA Cluster
############################################################################################
enable_openshift_virtualization    = false //Enable OpenShift Virtualization module
enable_advanced_cluster_management = false //Enable Advanced Cluster Management module

############################################################################################
//Variables Tags for resources managed by Terraform
############################################################################################
tag_expire_by   = "value" //The tag_expire_by variable must be in the format YYYY-MM-DD
tag_environment = "value" //The name of the environment variable must end with '-tf'
