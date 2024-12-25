import logging
import os
from azure.storage.blob import BlobServiceClient
from azure.identity import ManagedIdentityCredential
from azure.keyvault.secrets import SecretClient
import gnupg

import azure.functions as func

def main(blob: func.InputStream):
    logging.info(f"Processing blob: {blob.name}")

    # Initialize Managed Identity Credential
    credential = ManagedIdentityCredential()

    # Initialize BlobServiceClient for Storage Account B
    blob_service_client_b = BlobServiceClient(account_url=os.getenv("STORAGE_B_ACCOUNT_URL"), credential=credential)
    container_client_b = blob_service_client_b.get_container_client(os.getenv("STORAGE_B_CONTAINER_NAME"))

    # Initialize Key Vault client with Managed Identity
    key_vault_url = os.getenv("KEY_VAULT_URL")
    secret_client = SecretClient(vault_url=key_vault_url, credential=credential)
    pgp_key_secret = secret_client.get_secret(os.getenv("PGP_KEY_SECRET_NAME"))

    # Initialize GPG
    gpg = gnupg.GPG()
    gpg.import_keys(pgp_key_secret.value)

    # Decrypt the blob
    decrypted_data = gpg.decrypt(blob.read())

    if not decrypted_data.ok:
        logging.error("Decryption failed")
        return

    # Upload decrypted data to Storage Account B
    blob_client_b = container_client_b.get_blob_client(blob.name)
    blob_client_b.upload_blob(decrypted_data.data, overwrite=True)

    logging.info(f"Decrypted blob uploaded to Storage Account B: {blob.name}")
