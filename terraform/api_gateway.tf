# HTTP API Gateway
resource "aws_apigatewayv2_api" "agent" {
  name          = "enterprise-ai-agent-api"
  protocol_type = "HTTP"
}


# Connect API Gateway to the Lambda function
resource "aws_apigatewayv2_integration" "lambda" {
  api_id = aws_apigatewayv2_api.agent.id

  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.agent.invoke_arn
  payload_format_version = "2.0"
}


# POST /ask route
resource "aws_apigatewayv2_route" "ask" {
  api_id = aws_apigatewayv2_api.agent.id

  route_key = "POST /ask"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Where API Gateway will write request logs (auto-deletes after 1 day = low cost customize retention as needed)
resource "aws_cloudwatch_log_group" "api_gw_access_logs" {
  name              = "/aws/apigateway/enterprise-ai-agent-api"
  retention_in_days = 1
}


# Default stage with automatic deployment
resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.agent.id

  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 1
    throttling_rate_limit  = 1 # intentional — single tester, anti-abuse guard
  }

  # Send every request's basic info (IP, time, status code) to CloudWatch so we can see who's calling the API
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_access_logs.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      ip               = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      routeKey         = "$context.routeKey"
      status           = "$context.status"
      responseLength   = "$context.responseLength"
      integrationError = "$context.integration.error"
    })
  }
}


# Allow API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway" {
  statement_id = "AllowAPIGatewayInvoke"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.agent.function_name

  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.agent.execution_arn}/*/*"
}


# Display the API endpoint after deployment
output "api_url" {
  description = "HTTP API endpoint for the AI agent"
  value       = aws_apigatewayv2_stage.default.invoke_url
  sensitive   = true
}

