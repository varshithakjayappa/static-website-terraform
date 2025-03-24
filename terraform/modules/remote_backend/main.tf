# IAM user for Terraform
resource "aws_iam_user" "terraform_user" {
  name = var.iam_user_name
  tags = {
    tag-key = var.iam_user_name
  }
}

# Attaching AdministratorAccess managed policy to the IAM user
resource "aws_iam_user_policy_attachment" "admin_policy_attachment" {
  user       = aws_iam_user.terraform_user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = var.bucket_name
  tags = {
    Name = var.bucket_name
  }
}

# Enable versioning for S3 bucket
resource "aws_s3_bucket_versioning" "versioning_enabled" {
  bucket = aws_s3_bucket.terraform_state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket policy
resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = aws_s3_bucket.terraform_state_bucket.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Statement1",
        "Principal" : { "AWS" : "${aws_iam_user.terraform_user.arn}" },
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket"
        ],
        "Resource" : "${aws_s3_bucket.terraform_state_bucket.arn}"
      },
      {
        "Sid" : "Statement2",
        "Principal" : { "AWS" : "${aws_iam_user.terraform_user.arn}" },
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject"
        ],
        "Resource" : "${aws_s3_bucket.terraform_state_bucket.arn}/*"
      }
    ]
  })
}

# Create DynamoDB Policy (Optional)
resource "aws_iam_policy" "dynamodb_policy" {
  name        = "DynamoDBLockAccessPolicy"
  description = "Policy for managing DynamoDB state locking"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "dynamodb:PutItem",
          "dynamodb:GetItem"
        ],
        "Resource": "${aws_dynamodb_table.state_lock_table.arn}"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "dynamodb_policy_attachment" {
  user       = aws_iam_user.terraform_user.name
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}

#dynamodb for state locking
resource "aws_dynamodb_table" "state_lock_table" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockId"

  attribute {
    name = "LockId"
    type = "S"
  }
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = var.dynamodb_table_name
  }
}
