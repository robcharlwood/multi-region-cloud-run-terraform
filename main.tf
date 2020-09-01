provider "google" {
  version     = "~> 3.37.0"
  credentials = file("./.keys/terraform.json")
  project     = var.project
  region      = var.region
}

provider "google-beta" {
  version     = "~> 3.37.0"
  credentials = file("./.keys/terraform.json")
  project     = var.project
  region      = var.region
}

resource "google_project_service" "service" {
  count                      = length(var.project_services)
  project                    = var.project
  service                    = element(var.project_services, count.index)
  disable_on_destroy         = false
  disable_dependent_services = false
}

provider "null" {
  version = "~> 2.1.2"
}

provider "random" {
  version = "~> 2.3"
}

module "network" {
  source   = "./network"
  services = google_project_service.service
}

module "ssl" {
  source   = "./ssl"
  domain   = var.domain
  services = google_project_service.service
}

module "dns" {
  source    = "./dns"
  static_ip = module.network.static_ip
  domain    = var.domain
  services  = google_project_service.service
}

module "service-accounts" {
  source   = "./service-accounts"
  services = google_project_service.service
}

module "compute" {
  source                = "./compute"
  image_name            = var.image_name
  image_version         = var.image_version
  registry              = var.registry
  project               = var.project
  services              = google_project_service.service
  service_account_email = module.service-accounts.cloud_run_email
  static_ip_id          = module.network.static_ip
  ssl_cert_id           = module.ssl.id
}
