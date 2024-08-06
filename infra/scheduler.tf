resource "google_cloud_scheduler_job" "workflow_scheduler" {
  name      = "wf-stg-to-srv-scheduler-job"
  schedule  = "* 19 * * *" # Schedule every 5 minutes
  time_zone = "Etc/UTC"
  region    = var.region
  project   = var.project_id
  http_target {
    uri         = "https://workflowexecutions.googleapis.com/v1/projects/${var.project_id}/locations/${var.region}/workflows/${google_workflows_workflow.wf-stg-to-srv["wf-stg_to-srv"].name}/executions"
    http_method = "POST"
    oauth_token {
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
      service_account_email = "wf-stg-to-srv-d@event-trigger-cloud-storage.iam.gserviceaccount.com"
    }
    headers = {
      "Content-Type" = "application/json",
      "User-Agent"   = "Google-Cloud-Scheduler"
    }
    body = base64encode(<<EOF
      {"argument":"{
      \"project_id\":\"${var.project_id}\",\"dataset_id\":\"${google_bigquery_dataset.orders_dataset["stg_dataset"].dataset_id}\",\"stored_procedure_name\" : \"${google_bigquery_routine.staging_to_serving["stg-to-srv"].routine_id}\",\"location\":\"${var.region}\"}"}
    EOF
    )
  }
}