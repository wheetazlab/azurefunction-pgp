#!/bin/bash

# Variables
RESOURCE_GROUP="myResourceGroup"
FUNCTION_STORAGE_ACCOUNT_NAME="<your_function_storage_account_name>"
FUNCTION_APP_NAME="<your_function_app_name>"
STORAGE_ACCOUNT_DST_NAME="<your_storage_account_dst_name>"
KEY_VAULT_NAME="<your_key_vault_name>"

# Remove the function app
if az functionapp show --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
  echo "Removing function app: $FUNCTION_APP_NAME"
  az functionapp delete --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP
else
  echo "Function app $FUNCTION_APP_NAME does not exist"
fi

# Remove the storage account for the function app
if az storage account show --name $FUNCTION_STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
  echo "Removing storage account for the function app: $FUNCTION_STORAGE_ACCOUNT_NAME"
  az storage account delete --name $FUNCTION_STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP --yes
else
  echo "Storage account $FUNCTION_STORAGE_ACCOUNT_NAME does not exist"
fi

# Remove Storage Account DST
if az storage account show --name $STORAGE_ACCOUNT_DST_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
  echo "Removing storage account DST: $STORAGE_ACCOUNT_DST_NAME"
  az storage account delete --name $STORAGE_ACCOUNT_DST_NAME --resource-group $RESOURCE_GROUP --yes
else
  echo "Storage account DST $STORAGE_ACCOUNT_DST_NAME does not exist"
fi

# Remove the Key Vault if empty
if az keyvault show --name $KEY_VAULT_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
  if [ $(az keyvault secret list --vault-name $KEY_VAULT_NAME --query "length(@)") -eq 0 ]; then
    echo "Removing empty Key Vault: $KEY_VAULT_NAME"
    az keyvault delete --name $KEY_VAULT_NAME --resource-group $RESOURCE_GROUP
  else
    echo "Key Vault $KEY_VAULT_NAME is not empty, not removing"
  fi
else
  echo "Key Vault $KEY_VAULT_NAME does not exist"
fi

# Remove the resource group if empty
if az group show --name $RESOURCE_GROUP &> /dev/null; then
  if [ $(az resource list --resource-group $RESOURCE_GROUP --query "length(@)") -eq 0 ]; then
    echo "Removing empty resource group: $RESOURCE_GROUP"
    az group delete --name $RESOURCE_GROUP --yes --no-wait
  else
    echo "Resource group $RESOURCE_GROUP is not empty, not removing"
  fi
else
  echo "Resource group $RESOURCE_GROUP does not exist"
fi
