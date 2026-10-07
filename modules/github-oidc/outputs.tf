output "role_arns" {
  description = "Deploy role ARN for each GitHub Environment"
  value       = { for environment, role in aws_iam_role.deploy : environment => role.arn }
}
