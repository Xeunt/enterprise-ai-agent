terraform {
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket = "enterprise-ai-document-agent-tfstate"
    key    = "dev/terraform.tfstate"
    region = "ap-southeast-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    # Needed to auto-generate the random API key in lambda.tf
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}



provider "aws" {
  region = "ap-southeast-1"
}