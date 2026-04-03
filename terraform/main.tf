provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_artifact_registry_repository" "app" {
  location      = var.region
  repository_id = "app-images"
  format        = "DOCKER"
}

resource "google_container_cluster" "primary" {
  name     = "gke-gitops-cluster"
  location = var.zone

  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection = false
}

resource "google_service_account" "gke_nodes" {
  account_id   = "gke-gitops-node-sa"
  display_name = "GKE GitOps Node Service Account"
}

resource "google_container_node_pool" "nodes" {
  name       = "default-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  autoscaling {
  min_node_count = 1
  max_node_count = 3
}

  node_config {
    machine_type = "e2-standard-2" # increased to comfortably run system pods, ArgoCD, and Grafana
    disk_size_gb = 50
    service_account = google_service_account.gke_nodes.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}


resource "google_artifact_registry_repository_iam_member" "node_pull" {
  location   = var.region
  repository = google_artifact_registry_repository.app.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "node_sa_default_node_sa_role" {
  project = var.project_id
  role    = "roles/container.defaultNodeServiceAccount"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}