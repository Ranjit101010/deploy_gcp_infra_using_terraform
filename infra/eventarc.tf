resource "google_eventarc_trigger" "default" {
  name     = "trigger-wf-for-pubsub-topic-d"
  location = var.region

  # Capture objects changed in the bucket
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }
  matching_criteria {
    attribute = "bucket"
    value     = google_storage_bucket.buckets["bucket-archive-objects-d"].name
  }
  # Send events to Workflows
  destination {
    workflow = google_workflows_workflow.wf-stg-to-srv["wf-stg_to-srv"].id
  }
  service_account = "wf-stg-to-srv-d@event-trigger-cloud-storage.iam.gserviceaccount.com"
}