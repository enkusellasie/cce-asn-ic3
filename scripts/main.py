from google.cloud import storage
import functions_framework
import os
import string
import random
import datetime
import time

BUCKET = os.environ['BUCKET']
KMS_KEY = os.environ['KMS_KEY']

@functions_framework.http
def upload(request):

    if upload_blob_with_kms(BUCKET,KMS_KEY):
        return ("File uploaded successfully",200)
    else:
        return ("An error ocurred while uploading",500)

@functions_framework.http
def download(request):
    """Uploads a file to the bucket, encrypting it with the given KMS key."""

    storage_client = storage.Client()
    bucket = storage_client.bucket(BUCKET)
    # Get all objects (blobs) in the bucket
    blobs = bucket.list_blobs()

    if blobs:
        # Sort blobs by their updated timestamp (most recent first)
        most_recent_blob = sorted(blobs, key=lambda blob: blob.updated, reverse=True)[0]
        return most_recent_blob.download_as_text()
    else:
        return None  # Bucket is empty

def upload_blob_with_kms(
    bucket_name, kms_key_name,
):
    """Uploads a file to the bucket, encrypting it with the given KMS key."""

    destination_blob_name = "generated-file-" + unique_filename()

    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(destination_blob_name, kms_key_name = kms_key_name)

    
    generation_match_precondition = 0
    data = "This is an encrypted data with random id = {} uploaded at {}".format(id_generator(),time.time())

    try:
        blob.upload_from_string(data, if_generation_match=generation_match_precondition)
        print(
            "File {} uploaded to {} with encryption key {}.".format(
            data, destination_blob_name, kms_key_name
            )
        )
        return True
    except Exception as e:
        print("An error occured: {}".format(e))
        return False

def unique_filename():
    """Generates unique filename."""
    formatted_timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H:%M:%S")
    return formatted_timestamp  # Output: e.g., 2024-02-23 12:25:13

def id_generator(size=30, chars=string.ascii_uppercase + string.digits):
    """Generates unique string to be uploaded."""
    return ''.join(random.choice(chars) for _ in range(size))