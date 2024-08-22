terraform {
  required_version = ">= 1.9.3"
  required_providers {
    # https://registry.terraform.io/providers/hashicorp/google/5.42.0
    google = {
      source  = "hashicorp/google"
      version = "5.42.0"
    }
  }
}
