###################################################################
//Variables for ROSA Cluster credentials
###################################################################
kubeconfig_path = "~/.kube/config"
token           = "value"
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
startingCSV                     = "k10-kasten-operator-term-rhmp.v7.5.7" //if you want to install the 7.5.7 version, otherwise you can change it to the latest version


