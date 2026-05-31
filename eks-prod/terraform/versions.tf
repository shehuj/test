terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Remote state — create the bucket and DynamoDB table before init.
  # See README for bootstrap instructions.
  backend "s3" {
    bucket         = "bathbucket31"
    key            = "eks-prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "dyning_table"
    encrypt        = true
  }
}
