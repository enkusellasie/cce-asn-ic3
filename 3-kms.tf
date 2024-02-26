# CMEK KMS key ring
resource "google_kms_key_ring" "keyring" {
  name     = "keyring"
  location = "us"
}

# CMEK KMS encryption key to encrypt and decrypt files uploaded to storage bucket. 
resource "google_kms_crypto_key" "encryption_key" {
  name     = "encryption-key"
  key_ring = google_kms_key_ring.keyring.id
}

# Give the service agent ability to use the above CMEK to encrypt and decrypt.
data "google_iam_policy" "admin" {
  binding {
    role = "roles/cloudkms.cryptoOperator"

    members = [
      "serviceAccount:service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com",
    ]
  }
}

resource "google_kms_crypto_key_iam_policy" "crypto_key" {
  crypto_key_id = google_kms_crypto_key.encryption_key.id
  policy_data = data.google_iam_policy.admin.policy_data
}
