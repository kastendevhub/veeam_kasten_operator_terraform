############################################################################################
// Definition of the backend configuration for the Terraform state file
// This configuration is used to store the Terraform state file in an Azure Storage Account
############################################################################################
terraform {
  backend "azurerm" {
    storage_account_name = "value" //Azure Storage Account Name
    container_name       = "value" //Azure Storage Container Name
    key                  = "value" //Name of the Terraform state file
  }
}