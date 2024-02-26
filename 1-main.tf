resource "google_project_service" "apis" {
  for_each           = var.services
  project            = var.project
  service            = each.value
  disable_on_destroy = false

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = false
}

data "google_project" "project" {}
