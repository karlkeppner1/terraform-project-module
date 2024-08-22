# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network
resource "google_compute_network" "vpc" {
  name                                      = var.vpc_name == null ? "gke-vpc" : var.vpc_name
  description                               = var.vpc_description
  auto_create_subnetworks                   = var.auto_create_subnetworks == null ? false : var.auto_create_subnetworks
  routing_mode                              = var.vpc_routing_mode
  mtu                                       = var.vpc_mtu
  enable_ula_internal_ipv6                  = var.vpc_enable_ula_internal_ipv6
  internal_ipv6_range                       = var.vpc_internal_ipv6_range
  network_firewall_policy_enforcement_order = var.vpc_network_firewall_policy_enforcement_order
  project                                   = var.project_id
  delete_default_routes_on_create           = var.vpc_delete_default_routes_on_create
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork
# 1 subnet will be created per region in var.regions
resource "google_compute_subnetwork" "subnetwork" {
  for_each                         = { for i, v in var.regions : i => v }
  ip_cidr_range                    = cidrsubnet(var.vpc_cidr, ceil(log(length(var.regions), 2)), each.key)
  name                             = "${each.value}-subnet"
  network                          = google_compute_network.vpc.self_link
  description                      = var.subnetwork_description == null ? null : "${var.regions[each.value]} ${var.subnetwork_description}"
  purpose                          = "PRIVATE"
  private_ip_google_access         = var.subnetwork_private_ip_google_access
  private_ipv6_google_access       = var.subnetwork_private_ipv6_google_access
  region                           = each.value
  stack_type                       = var.subnetwork_stack_type
  ipv6_access_type                 = var.subnetwork_ipv6_access_type
  external_ipv6_prefix             = var.subnetwork_external_ipv6_prefix
  send_secondary_ip_range_if_empty = var.subnetwork_send_secondary_ip_range_if_empty
  project                          = var.project_id
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account
resource "google_service_account" "gke" {
  display_name = var.service_account_display_name == null ? "GKE Service Account" : var.service_account_display_name
  account_id   = var.service_account_account_id == null ? "gke-service-account" : var.service_account_account_id
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring
resource "google_kms_key_ring" "gke" {
  name     = var.kms_key_ring_name == null ? "gke-key-ring" : var.kms_key_ring_name
  location = var.regions[0]
  project  = var.project_id
}
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key
resource "google_kms_crypto_key" "gke" {
  name     = var.kms_crypto_key_name == null ? "gke-crypto-key" : var.kms_crypto_key_name
  key_ring = google_kms_key_ring.gke.id
  purpose  = "ENCRYPT_DECRYPT"
  lifecycle {
    prevent_destroy = false
  }
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_kms_key_ring_iam
resource "google_kms_key_ring_iam_member" "sa_kms" {
  key_ring_id = google_kms_key_ring.gke.id
  member      = "serviceAccount:${google_service_account.gke.email}"
  role        = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster
resource "google_container_cluster" "cluster" {
  name                     = var.cluster_name == null ? "default-cluster" : var.cluster_name
  initial_node_count       = 1
  location                 = var.regions[0]
  network                  = google_compute_network.vpc.self_link
  project                  = var.project_id
  subnetwork               = google_compute_subnetwork.subnetwork[0].self_link
  deletion_protection      = var.cluster_deletion_protection == null ? false : var.cluster_deletion_protection
  remove_default_node_pool = var.remove_default_node_pool == null ? true : var.remove_default_node_pool
  node_config {
    service_account = google_service_account.gke.email
  }
  database_encryption {
    state    = "ENCRYPTED"
    key_name = google_kms_crypto_key.gke.id
  }
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool
resource "google_container_node_pool" "general_purpose" {
  name               = var.cluster_node_pool_name == null ? "general-purpose" : var.cluster_node_pool_name
  cluster            = google_container_cluster.cluster.name
  initial_node_count = var.cluster_initial_node_count
  location           = var.regions[0]
  project            = var.project_id
  dynamic "autoscaling" {
    for_each = var.cluster_autoscaling == null ? [] : [var.cluster_autoscaling]
    content {
      location_policy      = var.cluster_autoscaling.location_policy
      max_node_count       = var.cluster_autoscaling.max_node_count
      min_node_count       = var.cluster_autoscaling.min_node_count
      total_max_node_count = var.cluster_autoscaling.total_max_node_count
      total_min_node_count = var.cluster_autoscaling.total_min_node_count
    }
  }
  management {
    auto_repair = true
  }
  node_config {
    boot_disk_kms_key           = var.cluster_node_config.boot_disk_kms_key
    disk_size_gb                = var.cluster_node_config.disk_size_gb
    disk_type                   = var.cluster_node_config.disk_type
    enable_confidential_storage = var.cluster_node_config.enable_confidential_storage
    image_type                  = var.cluster_node_config.image_type
    labels                      = var.cluster_node_config.labels
    local_ssd_count             = var.cluster_node_config.local_ssd_count
    logging_variant             = var.cluster_node_config.logging_variant
    machine_type                = var.cluster_node_config.machine_type
    min_cpu_platform            = var.cluster_node_config.min_cpu_platform
    node_group                  = var.cluster_node_config.node_group
    preemptible                 = var.cluster_node_config.preemptible
    resource_labels             = var.cluster_node_config.resource_labels
    resource_manager_tags       = var.cluster_node_config.resource_manager_tags
    service_account             = google_service_account.gke.email
    oauth_scopes                = ["https://www.googleapis.com/auth/cloud-platform"]
    spot                        = var.cluster_node_config.spot
    tags                        = var.cluster_node_config.tags
  }
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }
}
