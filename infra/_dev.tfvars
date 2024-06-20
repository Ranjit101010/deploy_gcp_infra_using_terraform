project_id      = "ranjit-1610110"
region          = "us-east1"
tf_state_bucket = "ranjit-1610110-tfstate"

# buckets for data processing and source code 
bucket = {
  bucket_fn = {
    name                     = "bucket-src-code-d"
    force_destroy            = true
    public_access_prevention = "enforced"
  },
  bucket_gcs_to_bq = {
    name                     = "bucket-gcs-to-bq-d"
    force_destroy            = true
    public_access_prevention = "enforced"
  }

}

# objects for source code
fn_object = {
  api_to_gcs_source = {
    type        = "zip"
    source_dir  = "../src"
    output_path = "./tmp/function.zip"
  }
}

# folders for processing api data
bucket_objects = {
  incoming_folder = {
    name    = "incoming/"
    content = "this is the incoming folder"
  },
  archive_folder = {
    name    = "archive/"
    content = "this is the archive folder"
  },
  error_folder = {
    name    = "error/"
    content = "this is the error folder"
  }
}

# bigquery dataset
bq_datasets = {
  stg_dataset = {
    dataset_id                  = "api_stg"
    description                 = "This is a stg dataset description"
    default_table_expiration_ms = 3600000
  }
  srv_dataset = {
    dataset_id                  = "api_srv"
    description                 = "This is a srv dataset description"
    default_table_expiration_ms = 3600000
  }
}

# biguqery dataset tables
bq_tables = {
  "stg_table" = {
    dataset_id        = "api_stg"
    table_id          = "api_gcs_to_bq"
    type              = "DAY"
    schema            = "C:\\Users\\Divya\\ranjit-1610110\\src\\schema\\stg_table.json"
    delete_protection = false
  }
}

# assign values to the cloud function
cloud_functions = {
  "api_to_gcs" = {
    name               = "src_to_gcs"
    description        = " api to gcs  function"
    runtime            = "python310"
    entry_point        = "api_to_gcs" # Set the entry point 
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60

  }
}