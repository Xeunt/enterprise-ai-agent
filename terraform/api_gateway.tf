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


# Default stage with automatic deployment
resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.agent.id

  name        = "$default"
  auto_deploy = true
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
}

