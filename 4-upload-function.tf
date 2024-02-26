resource "google_cloudfunctions_function" "upload_function" {
  name        = "upload-function"
  description = "Upload function that runs every 10 minutes by scheduler to upload encrypted files to a gcs bucket"
  runtime     = "python39"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.cloud-function-source-code-bucket.name
  source_archive_object = google_storage_bucket_object.source.name
  trigger_http          = true
  entry_point           = "upload"
  service_account_email = google_service_account.cloud_function_service_account.email
  ingress_settings      = "ALLOW_INTERNAL_ONLY" 

  environment_variables = {
    BUCKET = google_storage_bucket.files-bucket.name
    KMS_KEY = google_kms_crypto_key.encryption_key.id
  }
}

resource "google_cloud_scheduler_job" "invoke_cloud_function" {
  name        = "invoke-upload-function"
  description = "Schedule the HTTP trigger to run every 10 minutes for upload cloud function"
  schedule    = "*/10 * * * *" # runs every 10 minutes
  project     = var.project
  region      = var.region

  http_target {
    uri         = google_cloudfunctions_function.upload_function.https_trigger_url
    http_method = "POST"
    oidc_token {
      audience              = "${google_cloudfunctions_function.upload_function.https_trigger_url}/"
      service_account_email = google_service_account.scheduler_service_account.email
    }
  }
}