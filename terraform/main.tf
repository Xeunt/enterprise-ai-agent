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
  }
}

provider "aws" {
  region = "ap-southeast-1"
}