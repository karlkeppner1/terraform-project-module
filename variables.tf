variable "regions" {
  description = "List of GCP regions in which to create subnets. The first given region will be used for the GKE cluster."
  type        = list(string)
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

##################################################################################################
# *** VPC Variables ***
# Each variable is prefixed with vpc_ to avoid conflicts with other resources
# All supported optional variables default to null where possible
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network
##################################################################################################
variable "vpc_cidr" {
  description = "CIDR range for the VPC, the cidr will be split into subnets based on the number of regions as efficiently as possible."
  type        = string
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 1))
    error_message = "CIDR range must be a valid CIDR block"
  }
  validation {
    condition     = tonumber(split("/", cidrsubnet(var.vpc_cidr, ceil(log(length(var.regions), 2)), 0))[1]) < 30
    error_message = "CIDR range is too small for the number of regions given"
  }
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = null
}

variable "vpc_description" {
  description = "Description of the VPC"
  type        = string
  default     = null
}

variable "auto_create_subnetworks" {
  description = "Auto create subnetworks for the VPC"
  type        = bool
  default     = null
}

variable "vpc_routing_mode" {
  description = "Routing mode for the VPC"
  type        = string
  default     = null
}

variable "vpc_mtu" {
  description = "MTU for the VPC"
  type        = number
  default     = null
}

variable "vpc_enable_ula_internal_ipv6" {
  description = "Enable ULA internal IPv6 for the VPC"
  type        = bool
  default     = null
}

variable "vpc_internal_ipv6_range" {
  description = "Internal IPv6 range for the VPC, if not given, a range will be automatically chosen"
  type        = string
  default     = null
}

variable "vpc_network_firewall_policy_enforcement_order" {
  description = "Network firewall policy enforcement order for the VPC"
  type        = string
  default     = null
}

variable "vpc_delete_default_routes_on_create" {
  description = "Delete default routes on create for the VPC"
  type        = bool
  default     = null
}

##################################################################################################
# *** KMS Variables ***
# Each variable is prefixed with kms_ to avoid conflicts with other resources
# All supported optional variables default to null
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_kms_crypto_key_iam
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring
##################################################################################################
variable "kms_key_ring_name" {
  description = "Name of the KMS key ring"
  type        = string
  default     = null
}

variable "kms_crypto_key_name" {
  description = "Name of the KMS crypto key"
  type        = string
  default     = null
}

##################################################################################################
# *** Service Account Variables ***
# Each variable is prefixed with subnetwork_ to avoid conflicts with other resources
# All supported optional variables default to null
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork
##################################################################################################

variable "service_account_display_name" {
  description = "Display name of the service account"
  type        = string
  default     = null
}

variable "service_account_account_id" {
  description = "Account ID of the service account"
  type        = string
  default     = null
}

##################################################################################################
# *** Subnetwork Variables ***
# Each variable is prefixed with subnetwork_ to avoid conflicts with other resources
# All supported optional variables default to null
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork
##################################################################################################
variable "subnetwork_description" {
  description = "Description of the subnetworks"
  type        = string
  default     = null
}

variable "subnetwork_private_ip_google_access" {
  description = "Allow VMs in the subnetwork to access Google services using an external IP address"
  type        = bool
  default     = null
}

variable "subnetwork_private_ipv6_google_access" {
  description = "Allow VMs in the subnetwork to access Google services using an external IPv6 address"
  type        = bool
  default     = null
}

variable "subnetwork_stack_type" {
  description = "Stack type for the subnetwork"
  type        = string
  default     = null
}

variable "subnetwork_ipv6_access_type" {
  description = "IPv6 access type for the subnetwork"
  type        = string
  default     = null
}

variable "subnetwork_external_ipv6_prefix" {
  description = "External IPv6 prefix for the subnetwork"
  type        = string
  default     = null
}

variable "subnetwork_send_secondary_ip_range_if_empty" {
  description = "Send secondary IP range if empty for the subnetwork"
  type        = bool
  default     = null
}

##################################################################################################
# *** GKE Cluster and Node Variables ***
# Each variable is prefixed with cluster_ to avoid conflicts with other resources
# All supported optional variables default to null
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster
##################################################################################################
variable "cluster_autoscaling" {
  description = "Enable autoscaling for the node pool"
  type = object({
    location_policy      = optional(string, "ANY")
    max_node_count       = optional(number, 3)
    min_node_count       = optional(number, 0)
    total_max_node_count = optional(number, 0)
    total_min_node_count = optional(number, 0)
  })
  default = null
}

variable "cluster_node_pool_name" {
  description = "Name of the node pool"
  type        = string
  default     = null
}

variable "remove_default_node_pool" {
  description = "Remove the default node pool"
  type        = bool
  default     = null
}

variable "cluster_initial_node_count" {
  description = "Initial node count for the node pool per zone"
  type        = number
  default     = null
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = null
}

variable "cluster_deletion_protection" {
  description = "Enable deletion protection for the GKE cluster"
  type        = bool
  default     = null
}
variable "cluster_node_config" {
  description = "values for the node config"
  type = object({
    boot_disk_kms_key           = optional(string, null)
    disk_size_gb                = optional(number, 100)
    disk_type                   = optional(string, "pd-balanced")
    enable_confidential_storage = optional(bool, false)
    image_type                  = optional(string, "COS_CONTAINERD")
    labels                      = optional(map(string), {})
    local_ssd_count             = optional(number, 0)
    logging_variant             = optional(string, "DEFAULT")
    machine_type                = optional(string, "e2-medium")
    min_cpu_platform            = optional(number, null)
    node_group                  = optional(string, null)
    preemptible                 = optional(bool, false)
    resource_labels             = optional(map(string), {})
    resource_manager_tags       = optional(map(string), {})
    spot                        = optional(bool, false)
    tags                        = optional(list(string), [])
  })
  default = {
    boot_disk_kms_key           = null
    disk_size_gb                = 100
    disk_type                   = "pd-balanced"
    enable_confidential_storage = false
    guest_accelerator           = null
    image_type                  = "COS_CONTAINERD"
    labels                      = {}
    local_ssd_count             = 0
    logging_variant             = "DEFAULT"
    machine_type                = "e2-medium"
    min_cpu_platform            = null
    node_group                  = null
    preemptible                 = false
    resource_labels             = {}
    resource_manager_tags       = {}
    spot                        = false
    tags                        = []
  }
}
