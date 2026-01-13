
provider "google" {
  project = var.project_id
  region  = var.region
}

# Project under org & billing
resource "google_project" "project" {
  name            = var.project_id
  project_id      = var.project_id
  org_id          = var.org_id
  billing_account = var.billing_account
}

# Service accounts
resource "google_service_account" "terraform" {
  account_id   = "terraform-sa"
  display_name = "Terraform Service Account"
}

resource "google_service_account" "github_actions" {
  account_id   = "gha-sa"
  display_name = "GitHub Actions Service Account"
}

# IAM roles for service accounts
resource "google_project_iam_binding" "terraform_roles" {
  project = google_project.project.project_id
  role    = "roles/owner"
  members = ["serviceAccount:${google_service_account.terraform.email}"]
}

resource "google_project_iam_binding" "gha_roles" {
  project = google_project.project.project_id
  role    = "roles/container.admin"
  members = ["serviceAccount:${google_service_account.github_actions.email}"]
}

# VPC & subnet
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name                  = var.subnet_name
  ip_cidr_range         = "10.10.0.0/16"
  region                = var.region
  network               = google_compute_network.vpc.self_link
  private_ip_google_access = true
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.20.0.0/16"
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.30.0.0/20"
  }
}

# Cloud Router & NAT
resource "google_compute_router" "router" {
  name    = "nat-router"
  region  = var.region
  network = google_compute_network.vpc.self_link
}

resource "google_compute_router_nat" "nat" {
  name                               = "nat-config"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Firewall rules
resource "google_compute_firewall" "allow-internal" {
  name    = "allow-internal"
  network = google_compute_network.vpc.name
  allows {
    protocol = "all"
  }
  source_ranges = ["10.0.0.0/8"]
}

# GKE cluster
resource "google_container_cluster" "gke" {
  name               = var.cluster_name
  location           = var.region
  network            = google_compute_network.vpc.self_link
  subnetwork         = google_compute_subnetwork.subnet.self_link
  remove_default_node_pool = true
  initial_node_count = 1

  networking_mode    = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

resource "google_container_node_pool" "primary" {
  name       = "default-pool"
  location   = var.region
  cluster    = google_container_cluster.gke.name
  node_count = 2

  node_config {
    machine_type = "e2-standard-2"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    service_account = google_service_account.github_actions.email
  }
}
