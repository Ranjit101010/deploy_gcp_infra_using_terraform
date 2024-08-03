

resource "google_workflows_workflow" "wf-stg-to-srv" {
  for_each        = var.gcp_workflows
  name            = each.value.name
  region          = var.region
  description     = each.value.description
  source_contents = file("${path.module}/${each.value.source_contents}")
  service_account = each.value.service_account_email
}
