variable "project_services" {
  type = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "dns.googleapis.com",
    "run.googleapis.com",
    "compute.googleapis.com"
  ]
  description = "List of services to enable on the project."
}

variable "project" {
  type        = string
  description = "Name of project"
}

variable "region" {
  type        = string
  description = "Default region of project"
}

variable "registry" {
  description = "Container registry e.g eu.gcr.io or us.gcr.io"
  type        = string
}

variable "image_name" {
  description = "Name of the image to run on cloud run"
  type        = string
}

variable "image_version" {
  type        = string
  description = "Image version to deploy"
}

variable "domain" {
  type        = string
  description = "Your root domain without prefixes e.g example.com"
}
