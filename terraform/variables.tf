variable "credentials" {
  description = "Credentials"
  default     = "/home/david/.gc/trade-flows-analysis.json"
}

variable "project" {
  description = "Project"
  default     = "trade-flows-analysis"
}

variable "region" {
  description = "Region"
  default     = "europe-west6"
}

variable "location" {
  description = "Project location"
  default     = "EU"
}

variable "bq_dataset_name" {
  description = "Dataset Name"
  default     = "trade_flows_dataset"
}

variable "gcs_bucket_name" {
  description = "Bucket Name"
  default     = "trade-flows-bucket"
}

variable "gcs_storage_class" {
  description = "Bucket Storage Class"
  default     = "STANDARD"
}

variable "gcs_cluster_name" {
  description = "Cluster Name"
  default     = "trade-flows-cluster"
}