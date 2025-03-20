# Veeam Kasten K10 Terraform Automation for Red Hat OpenShift on AWS

This repository contains Terraform code to automate the installation of the Veeam Kasten K10 Operator on Red Hat OpenShift clusters running on AWS.

## Prerequisites

Before using this Terraform code, ensure you have the following:

- [Terraform](https://www.terraform.io/downloads.html) v1.0.0 or higher
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured
- [OpenShift CLI (oc)](https://docs.openshift.com/container-platform/4.13/cli_reference/openshift_cli/getting-started-cli.html) installed
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) installed
- Access to a Red Hat OpenShift cluster running on AWS with admin privileges
- OpenShift Cluster Manager API token

## Repository Structure

```
├── cleanup_script/             # Scripts for cleaning up Kasten resources
│   └── kasten_ns_cleanup.sh    # Script to clean up a stuck Kasten namespace
├── installer_tf/               # Main Terraform configuration
│   ├── main.tf                 # Core Terraform configuration for K10 installation
│   ├── output.tf               # Terraform outputs
│   ├── provider.tf             # Provider configuration
│   └── variables.tf            # Input variables
├── tfvars/                     # Variable definitions
│   └── values.tfvars           # Example variable values
├── LICENSE                     # MIT License
└── README.md                   # This file
```

## Setup Instructions

1. **Configure OpenShift CLI**:
   Ensure your OpenShift CLI is logged in to your cluster:

   ```bash
   oc login --token=<token> --server=<cluster-api-url>
   ```

2. **Configure AWS CLI**:
   Make sure your AWS CLI is configured with the appropriate credentials:

   ```bash
   aws configure
   ```

3. **Update the Variables File**:
   Update the values in `tfvars/values.tfvars` with your specific configuration:
   - `token`: Your OpenShift Cluster Manager API token
   - `startingCSV`: The version of Kasten K10 you want to deploy (default is v7.5.7)

4. **Initialize Terraform**:

   ```bash
   cd installer_tf
   terraform init
   ```

5. **Plan the Deployment**:

   ```bash
   terraform plan -var-file="../tfvars/values.tfvars"
   ```

6. **Deploy Kasten K10**:

   ```bash
   terraform apply -var-file="../tfvars/values.tfvars"
   ```

7. **Access the Kasten K10 Dashboard**:
   After the deployment completes, the Kasten K10 dashboard URL will be displayed in the Terraform output:

   ```hcl
   k10_dashboard_url = "https://k10-route-kasten-io.apps.<your-cluster-domain>/k10/"
   ```

## Cleanup

To remove the Kasten K10 installation:

1. **Terraform Destroy**:

   ```bash
   cd installer_tf
   terraform destroy -var-file="../tfvars/values.tfvars"
   ```

2. **If Namespace is Stuck in Terminating Status**:
   
   Use the cleanup script:

   ```bash
   cd ../cleanup_script
   chmod +x kasten_ns_cleanup.sh
   ./kasten_ns_cleanup.sh
   ```

## Features

This Terraform automation:

- Creates the required Kasten namespace
- Deploys the Kasten K10 Operator from the Red Hat Marketplace
- Configures OpenShift-specific settings and permissions
- Creates an EBS IO2 StorageClass optimized for Kasten
- Configures VolumeSnapshotClass for AWS EBS
- Creates a Kasten K10 instance with OpenShift Routes
- Automatically configures AWS infrastructure for Kasten K10

## Notes

- This installation configures AWS as the default storage location for K10
- The installation uses the stable channel for the K10 operator
- The EBS IO2 storage class is set as the default StorageClass
- The cleanup script helps remove Kasten resources when normal uninstallation doesn't work

## Troubleshooting

If you encounter issues:

1. Check the operator installation status:

   ```bash
   oc get csv -n kasten-io
   ```

2. Check the K10 platform status:

   ```bash
   oc get k10 -n kasten-io
   ```

3. View logs:

   ```bash
   oc logs -n kasten-io -l app=k10,component=jobs --tail=100
   ```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
