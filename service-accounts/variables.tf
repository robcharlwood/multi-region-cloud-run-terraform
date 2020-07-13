variable "cloud_run_service_account_iam_roles" {
  type        = list(string)
  default     = ["roles/run.serviceAgent"]
  description = "List of IAM roles to assign to the Cloud Run service account."
}
