locals {
  managed_domains = list(var.domain, "www.${var.domain}")
}

resource "random_id" "certificate" {
  byte_length = 4
  prefix      = "managed-ssl-cert-"

  keepers = {
    domains = join(",", local.managed_domains)
  }
  depends_on = [var.services]
}

resource "google_compute_managed_ssl_certificate" "cert" {
  provider = google-beta
  name     = random_id.certificate.hex

  lifecycle {
    create_before_destroy = true
  }

  managed {
    domains = local.managed_domains
  }
  depends_on = [var.services]
}
