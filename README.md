# azurefunction-pgp

This Azure Function is triggered when a file is dropped into a blob in Storage Account "SRC". The file is then decrypted using PGP with a key stored in Azure Key Vault. Once decrypted, the file is dumped into Storage Account "DST".

## Prerequisites

Before deploying the function, ensure the following secrets exist in your Azure Key Vault:

1. **SRC Connection String**: The connection string for Storage Account "SRC" must be stored as a secret in the Key Vault.
2. **PGP Key**: The PGP key must be stored as a secret in the Key Vault.

## Function Code

The function code is written in Python and performs the following steps:
1. Triggered by a new blob in Storage Account "SRC".
2. Retrieves the PGP key from Azure Key Vault.
3. Decrypts the blob using the PGP key.
4. Uploads the decrypted file to Storage Account "DST".

## Deployment Instructions

To deploy the function using Azure Cloud Shell, follow these steps:

1. Open the Azure Cloud Shell.
2. Clone the repository:

    ```bash
    git clone https://github.com/yourusername/azurefunction-pgp.git
    cd azurefunction-pgp
    ```

3. Make the deployment script executable:

    ```bash
    chmod +x deploy.sh
    ```

4. **Update the variables in `deploy.sh` and `local.settings.json` with your actual values.**

5. Run the deployment script:

    ```bash
    ./deploy.sh
    ```

This script will:

- Create a resource group.
- Create a storage account.
- Create a function app.
- Assign a system-assigned managed identity to the function app.
- Grant the managed identity access to Storage Account "SRC", Storage Account "DST", and the Key Vault.
- Deploy the function app code to the specified Azure Function App.

Make sure to replace the placeholders in the `deploy.sh` script with your actual values before running it.