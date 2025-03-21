############################################################################################
// ROSA Cluster Outputs
############################################################################################

output "cluster_id" {
  description = "The ID of the ROSA cluster"
  value       = module.rosa-classic.cluster_id
}

output "cluster_name" {
  description = "The name of the ROSA cluster"
  value       = var.cluster_name
}

output "openshift_version" {
  description = "The version of OpenShift installed"
  value       = var.openshift_version
}

output "cluster_status" {
  description = "The status of the ROSA cluster"
  value       = module.rosa-classic.state != "" ? module.rosa-classic.state : "unknown"
}

output "cluster_api_url" {
  description = "URL of the ROSA cluster API"
  value       = module.rosa-classic.api_url
}

output "cluster_console_url" {
  description = "URL of the ROSA cluster console"
  value       = module.rosa-classic.console_url
}

############################################################################################
// VPC and Network Outputs
############################################################################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = var.new_vpc_cidr
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = aws_subnet.public_subnet_cidr.id
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = aws_subnet.private_subnet_cidr.id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.rosa_gateway.id
}

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway"
  value       = aws_nat_gateway.nat.id
}

############################################################################################
// ROSA Authentication Outputs
############################################################################################

output "htpasswd_user_created" {
  description = "The username of the htpasswd identity provider"
  value       = var.htpasswd_idp_user
  sensitive   = false
}

output "cluster_admin_credentials" {
  description = "Instructions to get cluster admin credentials"
  value       = "Run: rosa describe cluster -c ${var.cluster_name} -o json | jq -r '.console.url'"
}

############################################################################################
// S3 Bucket Outputs
############################################################################################

output "s3_bucket_name" {
  description = "The name of the S3 bucket"
  value       = module.s3_bucket.s3_bucket_id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = module.s3_bucket.s3_bucket_arn
}

output "s3_bucket_region" {
  description = "The region of the S3 bucket"
  value       = var.aws_region
}

############################################################################################
// Compute Resources Outputs
############################################################################################

output "compute_machine_type" {
  description = "The instance type used for compute nodes"
  value       = var.compute_machine_type
}

output "compute_nodes_count" {
  description = "Number of compute nodes in the cluster"
  value       = 3  # Hardcoded to match your replicas setting
}

############################################################################################
// Command Line Helpers
############################################################################################

output "login_command" {
  description = "Command to log in to the cluster using htpasswd user"
  value       = "oc login $(rosa describe cluster -c ${var.cluster_name} -o json | jq -r '.api.url') -u ${var.htpasswd_idp_user} -p <your-password>"
  sensitive   = false
}

output "view_nodes_command" {
  description = "Command to view nodes in the cluster"
  value       = "oc get nodes"
}

output "cluster_info_command" {
  description = "Command to view detailed cluster information"
  value       = "rosa describe cluster -c ${var.cluster_name}"
}

############################################################################################
// End of output.tf
############################################################################################