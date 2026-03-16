output "verify_cluster" {
  description = "Run this command to verify the cluster is running"
  value       = "kubectl get nodes"
}

output "verify_runner" {
  description = "Check the runner status in GitHub: Settings > Actions > Runners"
  value       = "https://github.com/${var.github_repo}/settings/actions/runners"
}

output "app_url" {
  description = "App URL after a successful deploy"
  value       = "http://localhost:30080"
}
