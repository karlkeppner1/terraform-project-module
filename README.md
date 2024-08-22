# Terraform GCP GKE Cluster with KMS Encryption

This Terraform configuration sets up a Google Kubernetes Engine (GKE) cluster with a service account, KMS key ring, KMS crypto key, and IAM role binding. It also configures database encryption for the GKE cluster using the KMS crypto key. There are only 3 required variables to set up a GKE cluster. The cluster will be created in the first region given in the `regions` variable. Some best practices for networking, security, and GKE configuration have been baked in.

## Warnings

GCP does not immediately delete cryptograpfic keys. If `google_kms_crypto_key` is destroyed, a new name mush be provided via the `kms_crypto_key_name` variable.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed
- A Google Cloud Platform (GCP) project
- [Google Cloud SDK](https://cloud.google.com/sdk) installed and authenticated
- GCP account 
- GCP Service Account for terraform provider to authenticate to GCP account
- [GCP Service Usage API to be enabled.](https://console.cloud.google.com/apis/library/serviceusage.googleapis.com)
- [GCP Resource Manager API to be enabled.](https://console.cloud.google.com/apis/library/cloudresourcemanager.googleapis.com)
- [GCP Cloud Key Management Service (KMS) API to be enabled.](https://console.cloud.google.com/marketplace/product/google/cloudkms.googleapis.com)

## Files

### main.tf

This file contains the Terraform resources for creating the GKE service account, KMS key ring, KMS crypto key, IAM role binding, GKE cluster, and GKE node pool.

#### Created Resources

- **google_compute_network.vpc**
- **google_compute_subnetwork.subnetwork**
- **google_service_account.gke**
- **google_kms_key_ring.gke**
- **google_kms_crypto_key.gke**
- **google_kms_key_ring_iam_member.sa_kms**
- **google_container_cluster.cluster**
- **google_container_node_pool.general_purpose**

### variables.tf

This file defines the variables used in the Terraform configuration. Below is a detailed description of each variable.

#### Required Variables

- **project_id**
  - Type: `string`
  - Description: The ID of the project in which to create the resources.

- **regions**
  - Type: `list(string)`
  - Description: The regions in which to create the resources.

- **vpc_cidr**
  - Type: `string`
  - Description: CIDR range for the VPC, the cidr will be split into equally sized subnets based on the number of regions in `regions` as efficiently as possible.

#### Optional Variables

- **kms_crypto_key_name**
  - description: Name of the KMS crypto key
  - type: `string`
  - default: `null`

- **service_account_display_name**
  - description: Display name of the service account
  - type: `string`
  - default: `null`

- **service_account_account_id**
  - description: Account ID of the service account
  - type: `string`
  - default: `null`

- **subnetwork_description**
  - description: Description of the subnetworks
  - type: `string`
  - default: `null`

- **subnetwork_private_ip_google_access**
  - description: Allow VMs in the subnetwork to access Google services using an external IP address
  - type: `bool`
  - default: `null`

- **subnetwork_private_ipv6_google_access**
  - description: Allow VMs in the subnetwork to access Google services using an external IPv6 address
  - type: `bool`
  - default: `null`

- **subnetwork_stack_type**
  - description: Stack type for the subnetwork
  - type: `string`
  - default: `null`

- **subnetwork_ipv6_access_type**
  - description: IPv6 access type for the subnetwork
  - type: `string`
  - default: `null`

- **subnetwork_external_ipv6_prefix**
  - description: External IPv6 prefix for the subnetwork
  - type: `string`
  - default: `null`

- **subnetwork_send_secondary_ip_range_if_empty**
  - description: Send secondary IP range if empty for the subnetwork
  - type: `bool`
  - default: `null`

- **cluster_autoscaling**
  - description: Enable autoscaling for the node pool
  - type: object
     -  location_policy: optional `string`
     -  max_node_count: optional `number`
     -  min_node_count: optional `number`
     -  total_max_node_count: optional `number`
     -  total_min_node_count: optional `number`
  - default: 
    -   location_policy: `ANY`
    -   max_node_coun : `3`
    -   min_node_coun : `0`
    -   total_max_node_coun : `0`
    -   total_min_node_coun : `0`

- **cluster_node_pool_name**
  - description: Name of the node pool
  - type: `string`
  - default: `null`

- **remove_default_node_pool**
  - description: Remove the default node pool
  - type: `bool`
  - default: `null`

- **cluster_initial_node_count**
  - description: Initial node count for the node pool per zone
  - type: `number`
  - default: `null`

- **cluster_name**
  - description: Name of the GKE cluster
  - type: `string`
  - default: `null`

- **cluster_deletion_protection**
  - description: Enable deletion protection for the GKE cluster
  - type: `bool`
  - default: `null`

- **node_pool_config**
  - Type: `object`
  - Description: Configuration object for the node pool settings.
  - Properties:
    - **boot_disk_kms_key**
      - Type: `string`
      - Default: `null`
    - **disk_size_gb**
      - Type: `number`
      - Default: `100`
    - **disk_type**
      - Type: `string`
      - Default: `pd-balanced`
    - **enable_confidential_storage**
      - Type: `bool`
      - Default: `false`
    - **guest_accelerator**
      - Type: `object`
      - Default: `null`
    - **image_type**
      - Type: `string`
      - Default: `COS_CONTAINERD`
    - **labels**
      - Type: `map(string)`
      - Default: `{}`
    - **local_ssd_count**
      - Type: `number`
      - Default: `0`
    - **logging_variant**
      - Type: `string`
      - Default: `DEFAULT`
    - **machine_type**
      - Type: `string`
      - Default: `e2-medium`
    - **min_cpu_platform**
      - Type: `number`
      - Default: `null`
    - **node_group**
      - Type: `string`
      - Default: `null`
    - **preemptible**
      - Type: `bool`
      - Default: `false`
    - **resource_labels**
      - Type: `map(string)`
      - Default: `{}`
    - **resource_manager_tags**
      - Type: `map(string)`
      - Default: `{}`
    - **spot**
      - Type: `bool`
      - Default: `false`
    - **tags**
      - Type: `list(string)`
      - Default: `[]`

## Example usage

### Minimully viable configuration
```
module "gke_env" {
  source                              = "github.com/karlkeppner1/terraform-project-module?ref=v1.0.0"
  project_id                          = "abridge-demo"
  regions                             = ["us-west1"]
  vpc_cidr                            = "10.0.0.0/16"
}
```
### Configuration with multiple regions and additional variables
```
module "environment" {
  source                              = "github.com/karlkeppner1/terraform-project-module?ref=v1.0.0"
  project_id                          = "abridge-demo"
  regions                             = ["us-west1", "us-west2", "us-west3", "us-west4", "us-east1", "us-east4", "us-east5", "us-central1", "us-south1"]
  subnetwork_private_ip_google_access = true
  vpc_cidr                            = "10.0.0.0/16"
  vpc_name                            = "gke-env"
  kms_crypto_key_name                 = "gke-crypto-key2"
  kms_key_ring_name                   = "gke-key-ring2"

  cluster_node_config = {
    disk_size_gb = 50
    disk_type    = "pd-balanced"
    machine_type = "e2-medium"
  }
  cluster_autoscaling = {
    location_policy      = "ANY"
    max_node_count       = 3
    min_node_count       = 0
    total_max_node_count = 0
    total_min_node_count = 0
  }
}
```
