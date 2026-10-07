output "environment" {
  description = "GitHub Environment name"
  value       = github_repository_environment.this.environment
}
