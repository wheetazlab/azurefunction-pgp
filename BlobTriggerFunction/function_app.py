import logging
import os
from azure.storage.blob import BlobServiceClient
from azure.identity import ManagedIdentityCredential
import gnupg

import azure.functions as func

def main(blob: func.InputStream):
    logging.info(f"Processing blob: {blob.name}")

    # Initialize Managed Identity Credential
    credential = ManagedIdentityCredential()

    # Retrieve PGP key from environment variable
    pgp_key_secret = os.getenv("PGP_KEY_SECRET")

    # Initialize BlobServiceClient for Storage Account DST
    blob_service_client_dst = BlobServiceClient(account_url=os.getenv("STORAGE_DST_ACCOUNT_URL"), credential=credential)
    container_client_dst = blob_service_client_dst.get_container_client(os.getenv("STORAGE_DST_CONTAINER_NAME"))

    # Initialize GPG
    gpg = gnupg.GPG()
    gpg.import_keys(pgp_key_secret)

    # Decrypt the blob
    decrypted_data = gpg.decrypt(blob.read())

    if not decrypted_data.ok:
        logging.error("Decryption failed")
        return

    # Upload decrypted data to Storage Account DST
    blob_client_dst = container_client_dst.get_blob_client(blob.name)
    blob_client_dst.upload_blob(decrypted_data.data, overwrite=True)

    logging.info(f"Decrypted blob uploaded to Storage Account DST: {blob.name}")