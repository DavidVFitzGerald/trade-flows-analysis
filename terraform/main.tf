terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.18.1"
    }
  }
}

provider "google" {
  credentials = file(var.credentials)
  project     = var.project
  region      = var.region
}

resource "google_storage_bucket" "trade-flows-bucket" {
  name          = var.gcs_bucket_name
  location      = var.location
  force_destroy = true

  storage_class = var.gcs_storage_class
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}

resource "google_bigquery_dataset" "trade-flows-dataset" {
  dataset_id = var.bq_dataset_name
  location   = var.location
}

resource "google_dataproc_cluster" "trade-flows-cluster" {
  name   = var.gcs_cluster_name
  region = var.region
  project = var.project

  cluster_config {
    staging_bucket = var.gcs_bucket_name

    master_config {
      num_instances = 1
      machine_type  = "e2-standard-4"
      disk_config {
        boot_disk_type    = "pd-standard"
        boot_disk_size_gb = 30
      }
    }

    software_config {
      properties = {
        "dataproc:dataproc.allow.zero.workers" = "true"
      }
    }
    worker_config {
     num_instances = 0
    }

  }

}