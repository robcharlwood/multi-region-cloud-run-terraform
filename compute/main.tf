resource "google_cloud_run_service" "multi-region-cloud-run" {
  name     = "${var.image_name}-${element(var.locations, count.index)}"
  count    = length(var.locations)
  location = element(var.locations, count.index)

  template {
    spec {
      containers {
        image = "${var.registry}/${var.project}/${var.image_name}:${var.image_version}"
        resources {
          limits = {
            cpu    = "1000m"
            memory = "256M"
          }
        }
      }
      service_account_name = var.service_account_email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [var.services]
}

data "google_iam_policy" "cloud-run-no-auth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "cloud-run-no-auth-policy" {
  count       = length(google_cloud_run_service.multi-region-cloud-run)
  location    = element(google_cloud_run_service.multi-region-cloud-run.*.location, count.index)
  project     = element(google_cloud_run_service.multi-region-cloud-run.*.project, count.index)
  service     = element(google_cloud_run_service.multi-region-cloud-run.*.name, count.index)
  policy_data = data.google_iam_policy.cloud-run-no-auth.policy_data
  depends_on  = [var.services]
}

resource "google_compute_region_network_endpoint_group" "cloud-run-serverless-neg" {
  provider              = google-beta
  count                 = length(google_cloud_run_service.multi-region-cloud-run)
  name                  = "${element(var.locations, count.index)}-serverless-neg"
  network_endpoint_type = "SERVERLESS"
  region                = element(var.locations, count.index)
  cloud_run {
    service = element(google_cloud_run_service.multi-region-cloud-run.*.name, count.index)
  }
}

// google_compute_backend_service resource does not currently support serverless negs.
# resource "google_compute_backend_service" "cloud-run-backend-service" {
#   provider = google-beta
#   name     = "${var.image_name}-backend-service"
#   dynamic "backend" {
#     for_each = google_compute_region_network_endpoint_group.cloud-run-serverless-neg.*.self_link
#     content {
#       group = backend.value
#     }
#   }
# }

resource "null_resource" "cloud-run-backend-service-manual" {
  provisioner "local-exec" {
    environment = {
      project      = var.project
      service_name = var.image_name
    }
    command = <<EOT
      gcloud auth activate-service-account terraform@$project.iam.gserviceaccount.com \
          --project=$project \
          --key-file=./.keys/terraform.json \
          --configuration=$project
      gcloud config configurations activate $project
      gcloud compute backend-services create $service_name-backend-service --global
      gcloud beta compute backend-services add-backend $service_name-backend-service \
        --global \
        --network-endpoint-group=europe-west1-serverless-neg \
        --network-endpoint-group-region=europe-west1
      gcloud beta compute backend-services add-backend $service_name-backend-service \
        --global \
        --network-endpoint-group=us-east1-serverless-neg \
        --network-endpoint-group-region=us-east1
      gcloud beta compute backend-services add-backend $service_name-backend-service \
        --global \
        --network-endpoint-group=us-west1-serverless-neg \
        --network-endpoint-group-region=us-west1
      gcloud beta compute backend-services add-backend $service_name-backend-service \
        --global \
        --network-endpoint-group=asia-northeast1-serverless-neg \
        --network-endpoint-group-region=asia-northeast1
      EOT
  }

  provisioner "local-exec" {
    when = destroy
    environment = {
      project      = var.project
      service_name = var.image_name
    }
    command = <<EOT
      gcloud auth activate-service-account terraform@$project.iam.gserviceaccount.com \
        --project=$project \
        --key-file=./.keys/terraform.json \
        --configuration=$project
      gcloud config configurations activate $project
      gcloud compute backend-services delete $service_name-backend-service --global --quiet
      EOT
  }

  depends_on = [
    var.services,
    google_compute_region_network_endpoint_group.cloud-run-serverless-neg.0,
    google_compute_region_network_endpoint_group.cloud-run-serverless-neg.1,
    google_compute_region_network_endpoint_group.cloud-run-serverless-neg.2,
    google_compute_region_network_endpoint_group.cloud-run-serverless-neg.3,
  ]
}

resource "google_compute_url_map" "cloud-run-url-map" {
  name            = "${var.image_name}-url-map"
  description     = "${var.image_name} URL Map"
  default_service = "projects/${var.project}/global/backendServices/${var.image_name}-backend-service"
  # default_service = google_compute_backend_service.cloud-run-backend-service.id
  # remove me once backend service can be provisioned in terraform
  depends_on = [null_resource.cloud-run-backend-service-manual]
}

resource "google_compute_target_https_proxy" "cloud-run-https-proxy" {
  name             = "${var.image_name}-https-proxy"
  url_map          = google_compute_url_map.cloud-run-url-map.id
  ssl_certificates = [var.ssl_cert_id]
}

resource "google_compute_global_forwarding_rule" "cloud-run-global-forwarding-rule" {
  name       = "${var.image_name}-https-content-rule"
  target     = google_compute_target_https_proxy.cloud-run-https-proxy.id
  port_range = "443"
  ip_address = var.static_ip_id
}
