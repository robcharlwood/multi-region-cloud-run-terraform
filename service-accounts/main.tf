resource "google_service_account" "cloud-run" {
  account_id   = "cloud-run"
  display_name = "Cloud Run service account"
  description  = "Cloud Run service account"
}

resource "google_service_account_key" "cloud-run-key" {
  service_account_id = google_service_account.cloud-run.name
}

resource "google_project_iam_member" "cloud-run-service-account" {
  count  = length(var.cloud_run_service_account_iam_roles)
  role   = element(var.cloud_run_service_account_iam_roles, count.index)
  member = "serviceAccount:${google_service_account.cloud-run.email}"
}
