# Service account used by upload and download cloud functions. 
# They're sharing a single service account for simplicity. 
# Not recommended in a production usecase. 

resource "google_service_account" "cloud_function_service_account" {
  account_id   = "cloud-function-service-account"
  display_name = "Cloud function service account"
}

# Give object admin permission to the service account to allow read/write to the bucket.
resource "google_project_iam_member" "storage_object_creator_role" {
  project = var.project
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.cloud_function_service_account.email}"
}

# Allow all users to invoke the download function.
resource "google_cloudfunctions_function_iam_member" "invoker-permissions" {
  project        = google_cloudfunctions_function.download_function.project
  region         = google_cloudfunctions_function.download_function.region
  cloud_function = google_cloudfunctions_function.download_function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

# Service account attached to the scheduler.
resource "google_service_account" "scheduler_service_account" {
  account_id   = "scheduler-sa"
  display_name = "Service account for scheduler."
}

# Give only the scheduler invoker access to upload function. 
resource "google_cloudfunctions2_function_iam_member" "invoker" {
  project        = var.project
  location       = var.region
  cloud_function = google_cloudfunctions_function.upload_function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${google_service_account.scheduler_service_account.email}"
}