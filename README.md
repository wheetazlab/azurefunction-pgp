# azurefunction-pgp

This Azure Function is triggered when a file is dropped into a blob in Storage Account "A". The file is then decrypted using PGP with a key stored in Azure Key Vault. Once decrypted, the file is dumped into Storage Account "B".

## Setup Instructions

1. Create an Azure Function App.
2. Configure the Function App to use a Blob Storage trigger.
3. Set up Azure Key Vault and store your PGP key.
4. Configure the Function App to access the Key Vault.
5. Deploy the Azure Function code.

## Requirements

- Azure Function App
- Azure Storage Account "A"
- Azure Storage Account "B"
- Azure Key Vault
- PGP key stored in Azure Key Vault

## Function Code

The function code is written in Python and performs the following steps:
1. Triggered by a new blob in Storage Account "A".
2. Retrieves the PGP key from Azure Key Vault.
3. Decrypts the blob using the PGP key.
4. Uploads the decrypted file to Storage Account "B".