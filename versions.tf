provider "google" {
  project     = var.project
  region      = var.region
}

terraform {
  required_version = ">= 1.4.6"
  required_providers {

    google = {
      source  = "hashicorp/google"
      version = ">= 4.76, < 5.0"
    }
    random = {
      source = "hashicorp/random"
      version = "3.6.0"
    }
  }
}