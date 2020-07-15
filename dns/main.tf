resource "google_dns_managed_zone" "public-zone" {
  name        = replace(var.domain, ".", "-")
  dns_name    = "${var.domain}."
  description = "Domain for public site"
  depends_on  = [var.services]
}

resource "google_dns_record_set" "ns" {
  name         = google_dns_managed_zone.public-zone.dns_name
  managed_zone = google_dns_managed_zone.public-zone.name
  type         = "NS"
  ttl          = 60

  rrdatas    = google_dns_managed_zone.public-zone.name_servers
  depends_on = [var.services]
}

resource "google_dns_record_set" "a" {
  name         = google_dns_managed_zone.public-zone.dns_name
  managed_zone = google_dns_managed_zone.public-zone.name
  type         = "A"
  ttl          = 60

  rrdatas = [
    var.static_ip,
  ]
  depends_on = [var.services]
}

resource "google_dns_record_set" "a_www" {
  name         = "www.${google_dns_managed_zone.public-zone.dns_name}"
  managed_zone = google_dns_managed_zone.public-zone.name
  type         = "A"
  ttl          = 60

  rrdatas = [
    var.static_ip,
  ]
  depends_on = [var.services]
}
