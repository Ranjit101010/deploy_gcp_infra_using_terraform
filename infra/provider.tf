terraform {
  backend "gcs" {
    bucket = "event-trigger-cloud-storage-d"
    prefix = "terraform/state"
  }
} 