import logging
import os
from azure.storage.blob import BlobServiceClient
from azure.identity import ManagedIdentityCredential
import pgpy

import azure.functions as func

def main(blob: func.InputStream):
    logging.info(f"Processing blob: {blob.name}")

    # Initialize Managed Identity Credential
    credential = ManagedIdentityCredential()

    # Retrieve PGP key from environment variable
    pgp_key = os.getenv("PGP_KEY_SECRET")

    # Initialize BlobServiceClient for Storage Account DST
    blob_service_client_dst = BlobServiceClient(account_url=os.getenv("STORAGE_DST_ACCOUNT_URL"), credential=credential)
    container_client_dst = blob_service_client_dst.get_container_client(os.getenv("STORAGE_DST_CONTAINER_NAME"))

    # Initialize PGP key
    key, _ = pgpy.PGPKey.from_blob(pgp_key)

    # Decrypt the blob
    pgp_message = pgpy.PGPMessage.from_blob(blob.read())
    decrypted_data = key.decrypt(pgp_message)

    if not decrypted_data.is_encrypted:
        logging.error("Decryption failed")
        return

    # Upload decrypted data to Storage Account DST
    blob_client_dst = container_client_dst.get_blob_client(blob.name)
    blob_client_dst.upload_blob(decrypted_data.message, overwrite=True)

    logging.info(f"Decrypted blob uploaded to Storage Account DST: {blob.name}")
