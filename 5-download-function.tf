#Download cloud function. 
resource "google_cloudfunctions_function" "download_function" {
  name        = "download-function"
  description = "Function that downloads most recently uploaded file."
  runtime     = "python39"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.cloud-function-source-code-bucket.name
  source_archive_object = google_storage_bucket_object.source.name
  trigger_http          = true
  entry_point           = "download"
  service_account_email = google_service_account.cloud_function_service_account.email
  ingress_settings      = "ALLOW_INTERNAL_AND_GCLB" # Ingress setting set to allow traffic only through load balancer. This is to done to make sure security policy is enforced. 

  # Bucket name and KMS key passed as environment variables to cloud function
  environment_variables = {
    BUCKET = google_storage_bucket.files-bucket.name
    KMS_KEY = google_kms_crypto_key.encryption_key.id
  }
}

# Cloud Armor security policy to rate limit requests to download cloud function.
resource "google_compute_security_policy" "rate_limit_cloud_function" {
    name = "rate-limit-cloud-function"
    rule {
        action   = "rate_based_ban"
        priority = "2147483647"
        match {
            versioned_expr = "SRC_IPS_V1"
            config {
                src_ip_ranges = ["*"]
            }
        }
        description = "Cloud armor security policy to rate limit requests to download cloud function."

        rate_limit_options {
            conform_action = "allow"
            exceed_action = "deny(429)"

            enforce_on_key = "IP"
            ban_duration_sec = 60
            rate_limit_threshold {
                count = 210 # stop after 210 requests
                interval_sec = 60 * 10 # inteval of 10 minutes. 
            }
        }
    }
}

# Serverless Network Endpoit Group to serve as backend to loadbalancer to download cloud function.
resource "google_compute_region_network_endpoint_group" "function_neg" {
  name                  = "function-neg-2"
  network_endpoint_type = "SERVERLESS"
  region                = "us-central1"
  cloud_function {
    function = google_cloudfunctions_function.download_function.name
  }
}

# Module to setup up loadbalancer that will front download cloud function and will attach security policy.
# Since we haven't attached a domain name to the load balancer, we'll use the external IP created by this module to access the download function.
module "lb-http" {
  source                = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version               = "~> 9.0"
  name                  = "cloud-function-lb"
  project               = var.project
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ssl                             = false
  https_redirect                  = false
  create_address                  = true
  security_policy = google_compute_security_policy.rate_limit_cloud_function.self_link

  backends = {
    default = {
      description = null
      groups = [
        {
          group = google_compute_region_network_endpoint_group.function_neg.id
        }
      ]
      enable_cdn = false

      iap_config = {
        enable = false
      }

      log_config = {
        enable = true
      }
    }
  }
}



