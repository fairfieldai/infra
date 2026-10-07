output "function_name" {
  description = "Lambda function name, for deploying code with update-function-code"
  value       = aws_lambda_function.this.function_name
}

output "reminders_function_name" {
  description = "Lambda function that posts meetup announcements and reminders"
  value       = aws_lambda_function.reminders.function_name
}
