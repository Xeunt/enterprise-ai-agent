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
          "s3:GetObject",
          "s3:ListBucket"
        ]

        Resource = "arn:aws:s3:::enterprise-ai-document-agent-docs/documents/*"
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
}