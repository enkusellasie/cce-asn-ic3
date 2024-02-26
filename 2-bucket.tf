resource "random_id" "bucket" {
  byte_length = 8
}

# Storage bucket for storing source code for cloud functions
resource "google_storage_bucket" "cloud-function-source-code-bucket" {
  name     = "cloud-function-source-code-bucket-${random_id.bucket.hex}"
  location = "US"
}

# Storage bucket for storing encrypted files. 
resource "google_storage_bucket" "files-bucket" {
  name     = "encrypted-files-bucket-${random_id.bucket.hex}"
  location = "US"
}

resource "google_storage_bucket_object" "source" {
  name   = "source.zip"
  bucket = google_storage_bucket.cloud-function-source-code-bucket.name
  source = "./scripts/source.zip"
}