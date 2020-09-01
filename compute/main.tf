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

resource "google_compute_backend_service" "cloud-run-backend-service" {
  provider = google-beta
  name     = "${var.image_name}-backend-service"
  dynamic "backend" {
    for_each = google_compute_region_network_endpoint_group.cloud-run-serverless-neg.*.self_link
    content {
      group = backend.value
    }
  }
}

resource "google_compute_url_map" "cloud-run-url-map" {
  name            = "${var.image_name}-url-map"
  description     = "${var.image_name} URL Map"
  default_service = google_compute_backend_service.cloud-run-backend-service.id
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
