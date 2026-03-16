variable "github_repo" {
  description = "GitHub repository in owner/repo format (e.g. your-username/assignment-5-k8s-terraform)"
  type        = string
}

variable "runner_token" {
  description = "GitHub Actions runner registration token (expires in 1 hour)"
  type        = string
  sensitive   = true
}
