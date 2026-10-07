resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = var.api_id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.this.invoke_arn
  payload_format_version = "2.0"
}

# More specific than the API's ANY /{proxy+} route, so API Gateway sends these
# two paths here and everything else to the site API. CloudFront already
# forwards /api/* with every header and the raw body, which signature
# verification needs.
resource "aws_apigatewayv2_route" "this" {
  for_each = toset(["POST /api/discord/interactions", "POST /api/discord/events"])

  api_id    = var.api_id
  route_key = each.value
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "apigateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_execution_arn}/*/POST/api/discord/*"
}
