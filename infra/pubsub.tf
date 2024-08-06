resource "google_pubsub_topic" "log_topic" {
  name = var.pubsub_topic.name
}

resource "google_pubsub_subscription" "log_subscription" {
  name  = "archival-bucket-subscription-d"
  topic = google_pubsub_topic.log_topic.id
  # 20 minutes
  message_retention_duration = "1200s"
  retain_acked_messages      = true
  ack_deadline_seconds       = 20
  expiration_policy {
    ttl = "300000.5s"
  }
  retry_policy {
    minimum_backoff = "10s"
  }
  enable_message_ordering = true
}