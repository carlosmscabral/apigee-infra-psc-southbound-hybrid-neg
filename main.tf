/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# This script assumes that the VPC and proxy-subnet already exist prior to execution

# Subnet for Service Attachment
resource "google_compute_subnetwork" "psc-nat-svc-attachment-subnet" {
  name          = "psc-nat-svc-attachament-subnet"
  ip_cidr_range = var.subnet-psc-attachment
  region        = var.region
  network       = var.vpc_id
  purpose       = "PRIVATE_SERVICE_CONNECT"
  project       = var.project_id
}

# Hybrid NEG
resource "google_compute_network_endpoint_group" "neg" {
  name                  = "hybrid-neg"
  project               = var.project_id
  network               = var.vpc_id
  default_port          = var.dest_port
  zone                  = var.zone
  network_endpoint_type = "NON_GCP_PRIVATE_IP_PORT"
}

resource "google_compute_network_endpoint" "endpoint" {
  project                = var.project_id
  network_endpoint_group = google_compute_network_endpoint_group.neg.name
  port                   = var.dest_port
  ip_address             = var.dest_ip_address
  zone                   = var.zone
}

# # TCP Proxy ILB

resource "google_compute_region_health_check" "health_check" {
  name               = "lb-tcp-proxy-hc-80"
  project            = var.project_id
  region             = var.region
  timeout_sec        = 1
  check_interval_sec = 1

  tcp_health_check {
    port = var.dest_port
  }
}

resource "google_compute_region_backend_service" "backend_service" {
  name                  = "hybrid-neg-bs"
  project               = var.project_id
  region                = var.region
  health_checks         = [google_compute_region_health_check.health_check.id]
  load_balancing_scheme = "INTERNAL_MANAGED"
  protocol              = "TCP"

  backend {
    group           = google_compute_network_endpoint_group.neg.self_link
    balancing_mode  = "CONNECTION"
    failover        = false
    capacity_scaler = 1.0
    max_connections = 100
  }
}

resource "google_compute_region_target_tcp_proxy" "target_proxy" {
  provider        = google-beta
  name            = "lb-tcp-proxy-target-proxy"
  region          = var.region
  project         = var.project_id
  backend_service = google_compute_region_backend_service.backend_service.id
}

resource "google_compute_forwarding_rule" "forwarding_rule" {
  provider              = google-beta
  name                  = "lb-tcp-proxy-fr"
  project               = var.project_id
  region                = var.region
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = var.dest_port
  target                = google_compute_region_target_tcp_proxy.target_proxy.id
  network               = var.vpc_id
  subnetwork            = var.subnet-for-fr
  network_tier          = "PREMIUM"
}

# PSC Service Attachment
resource "google_compute_service_attachment" "service_attachment" {
  name                  = "psc-attachment-for-hybrid-neg"
  project               = var.project_id
  region                = var.region
  enable_proxy_protocol = false
  connection_preference = "ACCEPT_AUTOMATIC"
  nat_subnets           = [google_compute_subnetwork.psc-nat-svc-attachment-subnet.id]
  target_service        = google_compute_forwarding_rule.forwarding_rule.id
}