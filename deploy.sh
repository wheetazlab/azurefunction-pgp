#!/bin/bash

# Variables
RESOURCE_GROUP="myResourceGroup"
LOCATION="<your_location>"
FUNCTION_STORAGE_ACCOUNT_NAME="<your_function_storage_account_name>"
FUNCTION_APP_NAME="<your_function_app_name>"
STORAGE_ACCOUNT_DST_NAME="<your_storage_account_dst_name>"
KEY_VAULT_NAME="<your_key_vault_name>"
SUBSCRIPTION_ID="<your_subscription_id>"

# Check if resource group exists
if ! az group show --name $RESOURCE_GROUP &> /dev/null; then
  echo "Creating resource group: $RESOURCE_GROUP"
  az group create --name $RESOURCE_GROUP --location $LOCATION
else
  echo "Resource group $RESOURCE_GROUP already exists"
fi

# Check if the storage account for the function app exists
if ! az storage account show --name $FUNCTION_STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
  echo "Creating storage account for the function app: $FUNCTION_STORAGE_ACCOUNT_NAME"
  az storage account create --name $FUNCTION_STORAGE_ACCOUNT_NAME --location $LOCATION --resource-group $RESOURCE_GROUP --sku Standard_LRS
else
  echo "Storage account $FUNCTION_STORAGE_ACCOUNT_NAME already exists"
fi

# Check if Storage Account DST exists
if ! az storage account show --name $STORAGE_ACCOUNT_DST_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
  echo "Creating storage account DST: $STORAGE_ACCOUNT_DST_NAME"
  az storage account create --name $STORAGE_ACCOUNT_DST_NAME --location $LOCATION --resource-group $RESOURCE_GROUP --sku Standard_LRS
else
  echo "Storage account DST $STORAGE_ACCOUNT_DST_NAME already exists"
fi

# Check if Key Vault exists
if ! az keyvault show --name $KEY_VAULT_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
  echo "Creating Key Vault: $KEY_VAULT_NAME"
  az keyvault create --name $KEY_VAULT_NAME --resource-group $RESOURCE_GROUP --location $LOCATION
else
  echo "Key Vault $KEY_VAULT_NAME already exists"
fi

# Check if the function app exists
if ! az functionapp show --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
  echo "Creating function app: $FUNCTION_APP_NAME"
  az functionapp create --resource-group $RESOURCE_GROUP --consumption-plan-location $LOCATION --runtime python --functions-version 3 --name $FUNCTION_APP_NAME --storage-account $FUNCTION_STORAGE_ACCOUNT_NAME
else
  echo "Function app $FUNCTION_APP_NAME already exists"
fi

# Check if the managed identity is already assigned
if ! az functionapp identity show --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP --query principalId &> /dev/null; then
  echo "Assigning managed identity to function app: $FUNCTION_APP_NAME"
  az functionapp identity assign --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP
else
  echo "Managed identity already assigned to function app $FUNCTION_APP_NAME"
fi

# Get the managed identity principal ID
PRINCIPAL_ID=$(az functionapp identity show --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP --query principalId --output tsv)

# Check if the role assignment for Storage Account DST already exists
if ! az role assignment list --assignee $PRINCIPAL_ID --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_DST_NAME --query [].roleDefinitionName | grep -q "Storage Blob Data Contributor"; then
  echo "Granting access to Storage Account DST"
  az role assignment create --assignee $PRINCIPAL_ID --role "Storage Blob Data Contributor" --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_DST_NAME
else
  echo "Role assignment for Storage Account DST already exists"
fi

# Check if the Key Vault assignment already exists
if ! az keyvault show --name $KEY_VAULT_NAME --resource-group $RESOURCE_GROUP --query properties.accessPolicies[].objectId | grep -q $PRINCIPAL_ID; then
  echo "Granting access to Key Vault"
  az keyvault set-policy --name $KEY_VAULT_NAME --object-id $PRINCIPAL_ID --secret-permissions get
else
  echo "Key Vault assignment already exists"
fi

# Navigate to the function app directory
cd /root/azurefunction-pgp

# Initialize a new function app project (if not already done)
func init . --python

# Deploy the function app
# This command will deploy the function app in the current directory to the specified Azure Function App
func azure functionapp publish $FUNCTION_APP_NAME
