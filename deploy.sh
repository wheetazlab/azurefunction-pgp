#!/bin/bash

# Variables
RESOURCE_GROUP="myResourceGroup"
LOCATION="<your_location>"
STORAGE_ACCOUNT_NAME="<your_storage_account_name>"
FUNCTION_APP_NAME="<your_function_app_name>"
STORAGE_ACCOUNT_A_NAME="<storage_account_a_name>"
STORAGE_ACCOUNT_B_NAME="<your_storage_b_account_name>"
KEY_VAULT_NAME="<your_key_vault_name>"
SUBSCRIPTION_ID="<your_subscription_id>"

# Check if resource group exists
if ! az group show --name $RESOURCE_GROUP &> /dev/null; then
  echo "Creating resource group: $RESOURCE_GROUP"
  az group create --name $RESOURCE_GROUP --location $LOCATION
else
  echo "Resource group $RESOURCE_GROUP already exists"
fi

# Create a storage account
az storage account create --name $STORAGE_ACCOUNT_NAME --location $LOCATION --resource-group $RESOURCE_GROUP --sku Standard_LRS

# Check if Storage Account B exists
if ! az storage account show --name $STORAGE_ACCOUNT_B_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
  echo "Creating storage account B: $STORAGE_ACCOUNT_B_NAME"
  az storage account create --name $STORAGE_ACCOUNT_B_NAME --location $LOCATION --resource-group $RESOURCE_GROUP --sku Standard_LRS
else
  echo "Storage account B $STORAGE_ACCOUNT_B_NAME already exists"
fi

# Check if Key Vault exists
if ! az keyvault show --name $KEY_VAULT_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
  echo "Creating Key Vault: $KEY_VAULT_NAME"
  az keyvault create --name $KEY_VAULT_NAME --resource-group $RESOURCE_GROUP --location $LOCATION
else
  echo "Key Vault $KEY_VAULT_NAME already exists"
fi

# Create a function app
az functionapp create --resource-group $RESOURCE_GROUP --consumption-plan-location $LOCATION --runtime python --functions-version 3 --name $FUNCTION_APP_NAME --storage-account $STORAGE_ACCOUNT_NAME

# Assign a system-assigned managed identity to the function app
az functionapp identity assign --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP

# Get the managed identity principal ID
PRINCIPAL_ID=$(az functionapp identity show --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP --query principalId --output tsv)

# Grant access to Storage Account A
az role assignment create --assignee $PRINCIPAL_ID --role "Storage Blob Data Contributor" --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_A_NAME

# Grant access to Storage Account B
az role assignment create --assignee $PRINCIPAL_ID --role "Storage Blob Data Contributor" --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_B_NAME

# Grant access to Key Vault
az keyvault set-policy --name $KEY_VAULT_NAME --object-id $PRINCIPAL_ID --secret-permissions get

# Navigate to the function app directory
cd /root/azurefunction-pgp

# Initialize a new function app project (if not already done)
func init . --python

# Deploy the function app
# This command will deploy the function app in the current directory to the specified Azure Function App
func azure functionapp publish $FUNCTION_APP_NAME
