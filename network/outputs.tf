output "name" {
  value = google_compute_global_address.global-static-ip.name
}

output "static_ip" {
  value = google_compute_global_address.global-static-ip.address
}
