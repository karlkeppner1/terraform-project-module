output "google_compute_network" {
  value = google_compute_network.vpc
}
output "google_compute_subnetworks" {
  value = google_compute_subnetwork.subnetwork
}
output "google_service_account" {
  value = google_service_account.gke
}
output "google_kms_key_ring" {
  value = google_kms_key_ring.gke
}
output "google_kms_crypto_key" {
  value = google_kms_crypto_key.gke
}
output "google_kms_key_ring_iam_member" {
  value = google_kms_key_ring_iam_member.sa_kms
}
output "google_container_cluster" {
  value = google_container_cluster.cluster
}
output "google_container_node_pool" {
  value = google_container_node_pool.general_purpose
}
