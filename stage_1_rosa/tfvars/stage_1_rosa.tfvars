############################################################################################
//Variables for AWS Provider
############################################################################################
aws_region      = "value"
tag_expire_by   = "value" //The tag_expire_by variable must be in the format YYYY-MM-DD 
tag_environment = "value" //The name of the environment variable must end with '-tf'

############################################################################################
//Configuration of the AWS VPC for ROSA
############################################################################################
new_vpc_name = "value"

############################################################################################
//Variables for AWS ROSA Public Subnet
############################################################################################
public_subnet_name = "public_rosa_subnet"

############################################################################################
//Variables for AWS ROSA Private Subnet
############################################################################################
private_subnet_name = "private_rosa_subnet"

############################################################################################
//Variables ROSA Cluster
############################################################################################
cluster_name            = "value"
openshift_version       = "value" //for instance 4.17.19
compute_machine_type    = "value" //m5zn.metal - m5.xlarge
token                   = "value" //provision a ROSA cluster through the rhcs Terraform provider, an offline token access needs to be created by using the Red Hat Hybrid Cloud Console.
//https://console.redhat.com/openshift/token/rosa
htpasswd_idp_user       = "value" //The htpasswd_idp_user variable is the username that will be used to authenticate to the cluster.
htpasswd                = "value" //The htpasswd variable is the password that will be used to authenticate to the cluster.

############################################################################################
//Variables AWS S3 Bucket for ROSA
############################################################################################
bucket_name = "value" //The name of the S3 bucket for Veeam Kasten export. The name of the bucket variable must end with '-tf'
