terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

resource "null_resource" "cluster_and_runner" {
  provisioner "local-exec" {
    command     = "bash ../scripts/setup-runner.sh"
    working_dir = path.module

    environment = {
      GITHUB_REPO  = var.github_repo
      RUNNER_TOKEN = var.runner_token
    }
  }
}
