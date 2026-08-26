# Enterprise AI Document Agent

An enterprise-style agentic AI application built on AWS.

## Architecture

The solution uses:

- Amazon Bedrock Nova
- AWS Lambda
- Amazon S3
- Amazon API Gateway
- Terraform
- GitHub Actions
- GitHub OIDC

## Purpose

The AI agent can answer questions using documents stored in Amazon S3.

The agent can decide when it needs to retrieve information from S3 before generating an answer.

## Development Workflow

```text
VS Code
   ↓
GitHub
   ↓
GitHub Actions
   ↓
Terraform
   ↓
AWS DEV
