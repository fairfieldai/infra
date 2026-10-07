output "function_name" {
  description = "Lambda function name, for deploying code with update-function-code"
  value       = aws_lambda_function.this.function_name
}
