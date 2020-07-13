output "cloud_run_email" {
  value       = google_service_account.cloud-run.email
  description = "Service account email for Cloud Run services"
}

output "cloud_run_key" {
  value       = google_service_account_key.cloud-run-key.private_key
  description = "JSON key for the Cloud Run service account"
}
