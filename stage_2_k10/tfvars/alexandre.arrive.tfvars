############################################################################################
//Variables Tags for resources managed by Terraform
############################################################################################
tag_kasten_se   = "alexandre.arrive@veeam.com"
tag_expire_by   = "2024-09-10"
tag_environment = "rosa-k10-tf"

###################################################################
//Variables for ROSA Cluster credentials
###################################################################
kubeconfig_path = "~/.kube/config"
token           = "eyJhbGciOiJIUzUxMiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI0NzQzYTkzMC03YmJiLTRkZGQtOTgzMS00ODcxNGRlZDc0YjUifQ.eyJpYXQiOjE3NDE4Njg5NjEsImp0aSI6ImY4OWEyYTM0LWVmNzQtNGJjMi1iNmExLWI2ZmQyM2NjMTI4ZCIsImlzcyI6Imh0dHBzOi8vc3NvLnJlZGhhdC5jb20vYXV0aC9yZWFsbXMvcmVkaGF0LWV4dGVybmFsIiwiYXVkIjoiaHR0cHM6Ly9zc28ucmVkaGF0LmNvbS9hdXRoL3JlYWxtcy9yZWRoYXQtZXh0ZXJuYWwiLCJzdWIiOiJmOjUyOGQ3NmZmLWY3MDgtNDNlZC04Y2Q1LWZlMTZmNGZlMGNlNjphbGV4X2sxMCIsInR5cCI6Ik9mZmxpbmUiLCJhenAiOiJjbG91ZC1zZXJ2aWNlcyIsIm5vbmNlIjoiOTdiYzU1MjMtYTU2NS00YmJkLThlYzAtMzEwM2QzMjhkMTJiIiwic2lkIjoiNmM0ZjU0NjctZTg1NS00ZjJkLWEzMDYtNTU4NDYyY2YyYzE3Iiwic2NvcGUiOiJvcGVuaWQgYmFzaWMgYXBpLmlhbS5zZXJ2aWNlX2FjY291bnRzIHJvbGVzIHdlYi1vcmlnaW5zIGNsaWVudF90eXBlLnByZV9rYzI1IG9mZmxpbmVfYWNjZXNzIn0.pANthssWPLFUzT3wrQfqsgc_CPVjrgYdYqaNM3R3E_Wr9V1dgFuciLOmpnMQj0lKOtZE-Hz_VAJjIFXp024RJQ"
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
startingCSV                     = "k10-kasten-operator-term-rhmp.v7.5.7"

############################################################################################
// Module for ROSA Cluster
############################################################################################
enable_openshift_virtualization            = false
enable_advanced_cluster_management         = false

