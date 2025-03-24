terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.9"
    }
  }
}

provider "aws" {
 region = var.aws_region
}

module "backend" {
  source = "./remote_backend"
  iam_user_name = var.iam_user_name
  bucket_name = var.bucket_name
  dynamodb_table_name = var.dynamodb_table_name
}

output "iam_user_name" {
  value = module.backend.iam_user_arn
}