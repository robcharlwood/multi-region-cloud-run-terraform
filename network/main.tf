resource "google_compute_global_address" "global-static-ip" {
  name       = "global-static-ip"
  depends_on = [var.services]
}
