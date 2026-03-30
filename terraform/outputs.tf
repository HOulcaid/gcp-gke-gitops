output "cluster_name" { value = google_container_cluster.primary.name }
output "registry_url" { 
  value = "${var.region}-docker.pkg.dev/${var.project_id}/app-images"
}