terraform {
  backend "s3" {
    bucket         = "terraform-bucket-nature"
    key            = "website/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform_state_locks"
  }
}
