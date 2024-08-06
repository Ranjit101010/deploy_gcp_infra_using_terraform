resource "google_storage_notification" "notification" {
  bucket         = google_storage_bucket.buckets["bucket-archive-objects-d"].name
  payload_format = var.bucket_notifications.payload_format
  topic          = google_pubsub_topic.log_topic.id
  event_types    = var.bucket_notifications.event_types
}