############################################################################################
// Output Veeam Kasten Dashboard
############################################################################################

# Get the Kasten K10 route URL using data source - specifically looking for the gateway service
data "external" "kasten_route" {
  program = ["bash", "-c", "echo '{\"url\": \"'$(oc get route -n ${var.kasten_namespace} -o custom-columns=NAME:.metadata.name,SERVICE:.spec.to.name | grep gateway | awk '{print $1}' | xargs -I{} oc get route {} -n ${var.kasten_namespace} -o jsonpath='{.spec.host}' || echo 'not-available-yet')'\"}'"]
  
  # Only run this after K10 deployment is complete
  depends_on = [null_resource.create_aws_infrastructure_profile]
}

# Output the dashboard URL with HTTPS protocol
output "k10_dashboard_url" {
  description = "URL to access the Kasten K10 dashboard"
  value       = "https://${data.external.kasten_route.result.url}"
}