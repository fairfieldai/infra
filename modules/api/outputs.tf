output "api_domain_name" {
  description = "Domain name of the HTTP API default endpoint, for use as a CloudFront origin"
  value       = trimprefix(aws_apigatewayv2_api.this.api_endpoint, "https://")
}

output "function_name" {
  description = "Lambda function name, for deploying code with update-function-code"
  value       = aws_lambda_function.this.function_name
}

output "table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.this.name
}

output "api_id" {
  description = "HTTP API ID, for attaching more routes"
  value       = aws_apigatewayv2_api.this.id
}

output "api_execution_arn" {
  description = "HTTP API execution ARN, for Lambda invoke permissions"
  value       = aws_apigatewayv2_api.this.execution_arn
}
