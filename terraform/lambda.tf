data "aws_caller_identity" "current" {}

# Generates a random 32-character secret used to authenticate calls to /ask
resource "random_password" "api_key" {
  length  = 32
  special = false # alphanumeric only, so it's safe to pass in an HTTP header
}
resource "aws_iam_role" "agent_lambda" {
  name = "enterprise-ai-agent-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.agent_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_iam_role_policy" "agent_s3_access" {
  name = "enterprise-ai-agent-s3-access"
  role = aws_iam_role.agent_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = "arn:aws:s3:::enterprise-ai-document-agent-docs"
      },
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject"
        ]

        Resource = "arn:aws:s3:::enterprise-ai-document-agent-docs/documents/*"
      },
      {
        Effect = "Allow"

        Action = [
          "bedrock:InvokeModel"
        ]

        Resource = [
          "arn:aws:bedrock:ap-southeast-1:*:inference-profile/apac.amazon.nova-lite-v1:0",
          "arn:aws:bedrock:*::foundation-model/amazon.nova-lite-v1:0"
        ]
      }
    ]
  })
}


resource "aws_lambda_function" "agent" {
  function_name = "enterprise-ai-agent"

  role = aws_iam_role.agent_lambda.arn

  runtime = "python3.13"

  handler = "handler.lambda_handler"

  filename = "${path.module}/lambda.zip"

  source_code_hash = filebase64sha256(
    "${path.module}/lambda.zip"
  )

  # Makes the API key available inside the Lambda code as os.environ["API_KEY"]
  environment {
    variables = {
      API_KEY = random_password.api_key.result
    }
  }


}
# Lets you retrieve the generated key locally with: terraform output -raw api_key
# (never shown automatically in plan/apply logs because sensitive = true)
output "api_key" {
  description = "Secret key required to call the /ask endpoint"
  value       = random_password.api_key.result
  sensitive   = true
}