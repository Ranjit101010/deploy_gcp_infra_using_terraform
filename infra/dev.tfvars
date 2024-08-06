project_id      = "event-trigger-cloud-storage"
region          = "asia-south1"
tf_state_bucket = "event-trigger-cloud-storage-d"

bucket = {
  bucket-gcs-to-bq-d = {
    name                        = "bucket-gcs-to-bq-d"
    force_destroy               = true
    storage                     = "STANDARD"
    public_access_prevention    = "enforced"
    enabled                     = true
    uniform_bucket_level_access = true
  }

  cf-gcs-to-bq-d = {
    name                        = "cf-gcs-to-bq-d"
    force_destroy               = true
    storage                     = "STANDARD"
    public_access_prevention    = "enforced"
    enabled                     = true
    uniform_bucket_level_access = true
  }

  bucket-archive-objects-d = {
    name                        = "bucket-gcs-to-bq-archival-d"
    force_destroy               = true
    storage                     = "ARCHIVE"
    public_access_prevention    = "enforced"
    enabled                     = true
    uniform_bucket_level_access = true
  }
}

bucket_object = {
  "empty_folder" = {
    name    = "incoming/" # folder name should end with '/'
    content = " "         # content is ignored but should be non-empty
  }
}

zip-data = {
  "cf-src-code" = {
    file_type   = "zip"
    output_path = "/tmp/function-source.zip"
    source_dir  = "../src/gcs_to_bq/"
  }
}

gcp_functions = {
  "gcs-to-bq-d" = {
    name               = "cf-gcs-to-bq-d"
    description        = "This function is used to ingest data in bigquery"
    runtime            = "python310"
    entry_point        = "gcs_to_bq" # Set the entry point
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 120
    event_type         = "google.cloud.storage.object.v1.finalized"
    attribute          = "bucket"
  }
}

datasets = {
  "stg_dataset" = {
    dataset_id                  = "orders_stg_dataset"
    friendly_name               = "orders_stg"
    description                 = "This dataset is used to collect the data from source as it is "
    default_table_expiration_ms = 7 * 24 * 60 * 60 * 1000
    delete_protection           = false
  }

  "srv_dataset" = {
    dataset_id                  = "orders_srv_dataset"
    friendly_name               = "orders_srv"
    description                 = "This dataset is used to collect the tranform data from staging dataset "
    default_table_expiration_ms = 7 * 24 * 60 * 60 * 1000
  }
}

stg_tables = {
  "stg_table" = {
    name                = "orders_stg_table"
    deletion_protection = false
  }
}

srv_tables = {
  "latest_table" = {
    name                = "orders_latest_srv"
    deletion_protection = false
    schema              = "../src/serving_table_schema.json"
  }
  "history_table" = {
    name                = "orders_hst_srv"
    deletion_protection = false
    schema              = "../src/serving_table_schema.json"
  }
}

routines = {
  "stg-to-srv" = {
    routine_id      = "staging_to_serving"
    routine_type    = "PROCEDURE"
    definition_body = "../src/staging_to_serving.tftpl"
    language        = "SQL"
  }
}

gcp_workflows = {
  "wf-stg_to-srv" = {
    name                  = "wf-stg-to-srv-d"
    description           = "ingest the data in the serving table"
    source_contents       = "../src/wf_stg_to_srv.yaml"
    service_account_email = "wf-stg-to-srv-d@event-trigger-cloud-storage.iam.gserviceaccount.com"
  }
}


bucket_notifications = {
  payload_format = "JSON_API_V1"
  event_types    = ["OBJECT_FINALIZE"]
}

pubsub_topic = {
  name = "gcs-bucket-event-finalize-d"
}