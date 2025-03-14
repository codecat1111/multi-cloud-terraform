# GCP Firewall Rules
resource "google_compute_firewall" "web" {
  name    = "${var.project_name}-web-firewall"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80", "22"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["web-server"]
}

# Instance Template
resource "google_compute_instance_template" "web" {
  name_prefix  = "${var.project_name}-web-template-"
  machine_type = "e2-micro"

  disk {
    source_image = var.gcp_image_id
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public.id
    access_config {
      # Ephemeral IP
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
  EOF

  tags = ["web-server"]

  labels = {
    environment = var.environment
  }
}

# Health Check
resource "google_compute_health_check" "web" {
  name = "${var.project_name}-health-check"

  http_health_check {
    port = 80
  }
}

# Instance Group Manager
resource "google_compute_instance_group_manager" "web" {
  name = "${var.project_name}-igm"

  base_instance_name = "${var.project_name}-web"
  zone              = "${var.gcp_region}-a"
  target_size       = 2

  version {
    instance_template = google_compute_instance_template.web.id
  }

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.web.id
    initial_delay_sec = 300
  }
}

# Load Balancer Components
resource "google_compute_global_address" "web" {
  name = "${var.project_name}-lb-ip"
}

resource "google_compute_global_forwarding_rule" "web" {
  name       = "${var.project_name}-forwarding-rule"
  target     = google_compute_target_http_proxy.web.id
  port_range = "80"
  ip_address = google_compute_global_address.web.address
}

resource "google_compute_target_http_proxy" "web" {
  name    = "${var.project_name}-proxy"
  url_map = google_compute_url_map.web.id
}

resource "google_compute_url_map" "web" {
  name            = "${var.project_name}-url-map"
  default_service = google_compute_backend_service.web.id
}

resource "google_compute_backend_service" "web" {
  name        = "${var.project_name}-backend"
  protocol    = "HTTP"
  timeout_sec = 10
  enable_cdn  = false

  health_checks = [google_compute_health_check.web.id]

  backend {
    group = google_compute_instance_group_manager.web.instance_group
  }
}

# DNS Configuration
resource "google_dns_managed_zone" "main" {
  name     = replace(var.dns_zone_name, ".", "-")
  dns_name = "${var.dns_zone_name}."
}

resource "google_dns_record_set" "web" {
  name         = "www.${google_dns_managed_zone.main.dns_name}"
  managed_zone = google_dns_managed_zone.main.name
  type         = "A"
  ttl          = 300

  rrdatas = [google_compute_global_address.web.address]
}