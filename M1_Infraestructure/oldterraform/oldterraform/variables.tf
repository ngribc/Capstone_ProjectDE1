variable "credentials" {
  description = "My Credentials"
  default     = "<Path to your Service Account json file>"
  #ex: if you have a directory where this file is called keys with your service account json file
  #saved there as my-creds.json you could use default = "./keys/my-creds.json"
}

variable "location" {
  description = "Project Location"
  #Update the below to your desired location
  default     = "US"
}

variable "project" {
  description = "GCP Project ID"
  default     = "voice-ai-retail-project"
}

variable "region" {
  description = "Region for GCP resources"
  default     = "us-central1"
}

variable "gcs_bucket_name" {
  description = "My Storage Bucket Name"
  default     = "voice-ai-retail-2026-data-lake"
}

variable "gcs_storage_class" {
  description = "Bucket Storage Class"
  default     = "STANDARD"
}

variable "bq_dataset_name" {
  description = "BigQuery Dataset Name"
  default     = "voice_ai_retail_analytics"
}





