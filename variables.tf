variable "services" {
  type = set(string)
  default = [
    "cloudfunctions.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
    "run.googleapis.com",
    "cloudscheduler.googleapis.com"
  ]
}

variable "project" {
    type = string
}
variable "region" {
    type = string
    default = "us-central1"
}