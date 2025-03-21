# Terraform Deployment for ROSA and Veeam Kasten Operator

This repository contains Terraform code to deploy a Red Hat OpenShift Service on AWS (ROSA) cluster and the Veeam Kasten K10 operator for data protection and management.

## Prerequisites

- AWS CLI installed and configured with appropriate credentials
- Terraform (version 1.0.0 or higher)
- OpenShift CLI (`oc`) installed
- Red Hat OpenShift Cluster Manager token
- Optional: Azure CLI (if using Azure for the backend state)

## Deployment Process

The deployment is divided into two stages:
1. Stage 1: Deploy the ROSA cluster
2. Stage 2: Deploy the Veeam Kasten K10 Operator and optional components

## Stage 1: Deploy ROSA Cluster

### Step 1: Configure Backend State (Optional)

If you're using Azure for backend state storage:

1. Edit the backend configuration in `stage_1_rosa/backend.tf`:

   ```hcl
   terraform {
     backend "azurerm" {
       storage_account_name = "your-storage-account-name"
       container_name       = "your-container-name"
       key                  = "stage-1-rosa.tfstate"
     }
   }
   ```

2. Log in to Azure:

   ```bash
   az login
   ```

### Step 2: Configure Variables

1. Navigate to the stage_1_rosa directory:

   ```bash
   cd stage_1_rosa
   ```

2. Create or edit a `.tfvars` file in the `tfvars` directory. You can use the provided example as a template:

   ```bash
   cp tfvars/stage_1_rosa.tfvars tfvars/your-name.tfvars
   ```

3. Edit your `.tfvars` file with appropriate values:

   ```hcl
   aws_region      = "us-east-1"                 # Your AWS region
   tag_expire_by   = "2024-12-31"                # Expiration date for resources
   tag_environment = "my-rosa-env-tf"            # Environment name (must end with -tf)
   
   new_vpc_name    = "rosa-vpc-tf"               # Name for the new VPC (must end with -tf)
   
   cluster_name            = "my-rosa-cluster-tf" # ROSA cluster name (must end with -tf)
   openshift_version       = "4.17.19"            # OpenShift version
   compute_machine_type    = "m5.xlarge"          # AWS instance type
   token                   = "your-token"         # RHCS token
   htpasswd_idp_user       = "openshift-admin"    # Admin username
   htpasswd                = "secure-password"    # Admin password
   
   bucket_name = "my-rosa-bucket-tf"              # S3 bucket name (must end with -tf)
   ```

### Step 3: Initialize and Apply Terraform

1. Initialize Terraform:

   ```bash
   terraform init
   ```

2. Validate your configuration:

   ```bash
   terraform validate
   ```

3. Plan the deployment:

   ```bash
   terraform plan -var-file=tfvars/your-name.tfvars
   ```

4. Apply the configuration:

   ```bash
   terraform apply -var-file=tfvars/your-name.tfvars
   ```

5. Wait for the ROSA cluster to be deployed (this may take 30-40 minutes).

### Step 4: Verify the ROSA Cluster Deployment

1. Check the status of your ROSA cluster:

   ```bash
   rosa describe cluster -c your-cluster-name-tf
   ```

2. Configure the OpenShift CLI to connect to your cluster:

   ```bash
   rosa create admin --cluster=your-cluster-name-tf
   # Follow the instructions to log in
   ```

3. Verify the connection:

   ```bash
   oc get nodes
   ```

## Stage 2: Deploy Veeam Kasten K10 and Optional Components

### Step 1: Configure Backend State (Optional)

If you're using Azure for backend state storage:

1. Edit the backend configuration in `stage_2_k10/backend.tf`:

   ```hcl
   terraform {
     backend "azurerm" {
       storage_account_name = "your-storage-account-name"
       container_name       = "your-container-name"
       key                  = "stage-2-k10.tfstate"
     }
   }
   ```

### Step 2: Configure Variables

1. Navigate to the stage_2_k10 directory:

   ```bash
   cd ../stage_2_k10
   ```

2. Create or edit a `.tfvars` file in the `tfvars` directory. You can use the provided example as a template:

   ```bash
   cp tfvars/alexandre.arrive.tfvars tfvars/your-name.tfvars
   ```

3. Edit your `.tfvars` file with appropriate values:

   ```hcl
   tag_kasten_se   = "your.email@veeam.com"
   tag_expire_by   = "2024-12-31"
   tag_environment = "rosa-k10-tf"
   
   kubeconfig_path = "~/.kube/config"
   token           = "your-rhcs-token"
   
   kasten_ocp_project_description  = "Kubernetes data management platform"
   kasten_ocp_project_display_name = "Kasten K10"
   kasten_namespace                = "kasten-io"
   channel                         = "stable"
   installPlanApproval             = "Automatic"
   kasten_operator_name            = "k10-kasten-operator-term-rhmp"
   source_catalog                  = "redhat-marketplace"
   sourceNamespace                 = "openshift-marketplace"
   startingCSV                     = "k10-kasten-operator-term-rhmp.v7.5.7"
   
   enable_openshift_virtualization    = false # Set to true to enable OpenShift Virtualization
   enable_advanced_cluster_management = false # Set to true to enable OpenShift ACM
   ```

### Step 3: Initialize and Apply Terraform

1. Make sure you're logged in to your ROSA cluster:

   ```bash
   oc login --token=<token> --server=<server-url>
   ```

2. Initialize Terraform:

   ```bash
   terraform init
   ```

3. Validate your configuration:

   ```bash
   terraform validate
   ```

4. Plan the deployment:

   ```bash
   terraform plan -var-file=tfvars/your-name.tfvars
   ```

5. Apply the configuration:

   ```bash
   terraform apply -var-file=tfvars/your-name.tfvars
   ```

6. Wait for the Veeam Kasten K10 operator to be deployed (this may take 5-10 minutes).

### Step 4: Verify the Veeam Kasten K10 Deployment

1. Check that all K10 pods are running:

   ```bash
   oc get pods -n kasten-io
   ```

2. Access the Veeam Kasten K10 dashboard:

   ```bash
   echo "Kasten K10 Dashboard URL: $(terraform output -raw k10_dashboard_url)"
   ```

3. Log in to the dashboard using your OpenShift credentials.

## Optional Components

### OpenShift Virtualization

If you enabled OpenShift Virtualization in your `.tfvars` file (`enable_openshift_virtualization = true`), verify its deployment:

```bash
oc get pods -n openshift-cnv
```

### Advanced Cluster Management (ACM)

If you enabled OpenShift Advanced Cluster Management in your `.tfvars` file (`enable_advanced_cluster_management = true`), verify its deployment:

```bash
oc get pods -n open-cluster-management
```

## Cleanup

### Step 1: Destroy Stage 2 Resources

1. Navigate to the stage_2_k10 directory:

   ```bash
   cd stage_2_k10
   ```

2. Destroy the resources:

   ```bash
   terraform destroy -var-file=tfvars/your-name.tfvars
   ```

3. If resources are stuck in terminating state, use the cleanup scripts:

   ```bash
   bash kasten_ns_cleanup.sh
   bash acm_cleanup.sh # If ACM was enabled
   ```

### Step 2: Destroy Stage 1 Resources

1. Navigate to the stage_1_rosa directory:

   ```bash
   cd ../stage_1_rosa
   ```

2. Destroy the resources:

   ```bash
   terraform destroy -var-file=tfvars/your-name.tfvars
   ```

## Troubleshooting :wrench:

### Common Issues :warning:

1. **:no_entry_sign: Namespace stuck in terminating state**:
   Use the provided cleanup script:

   ```bash
   bash kasten_ns_cleanup.sh
   ```

2. **:key: Error creating AWS Infrastructure Profile**:
   Verify your AWS credentials and region:

   ```bash
   aws configure list
   ```

3. **:mag: CRD not found errors**:
   Wait longer for the operator to create all the CRDs, or restart the operator installation:

   ```bash
   oc delete subscription kasten-operator -n kasten-io
   oc delete operatorgroup kasten-operator-group -n kasten-io
   ```

4. **:computer: Unable to access K10 dashboard**:
   Check the route status:
   
   ```bash
   oc get routes -n kasten-io
   ```

## Support :lifebuoy:

For issues related to this Terraform code, please open an issue in the GitHub repository. :octocat:

For issues with Veeam Kasten K10, please contact Veeam support or visit the [Kasten documentation](https://docs.kasten.io/). :books:
