data "archive_file" "zip-file" {
  for_each    = var.zip-data
  type        = each.value.file_type
  output_path = each.value.output_path
  source_dir  = each.value.source_dir
}

resource "google_storage_bucket_object" "zip-object" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.buckets["cf-gcs-to-bq-d"].name
  source = data.archive_file.zip-file["cf-src-code"].output_path # Add path to the zipped function source code
}

resource "google_cloudfunctions2_function" "cloud_event_fn" {
  for_each    = var.gcp_functions
  name        = each.value.name
  location    = var.region
  description = each.value.description

  build_config {
    runtime     = each.value.runtime
    entry_point = each.value.entry_point # Set the entry point
    source {
      storage_source {
        bucket = google_storage_bucket.buckets["cf-gcs-to-bq-d"].name
        object = google_storage_bucket_object.zip-object.name
      }
    }
  }

  service_config {
    max_instance_count = each.value.max_instance_count
    available_memory   = each.value.available_memory
    timeout_seconds    = each.value.timeout_seconds
  }

  event_trigger {
    event_type = each.value.event_type
    event_filters {
      attribute = each.value.attribute
      value     = google_storage_bucket.buckets["bucket-gcs-to-bq-d"].name
    }
  }
}