module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  bucket = "sabratfstatebucket"
}

module "dynamodb_table" {
  source   = "terraform-aws-modules/dynamodb-table/aws"
  hash_key = "LockID"
  name     = "my_table"

  attributes = [
    {
      name = "LockID"
      type = "S"
    }
  ]
  tags = {
    Terraform   = "true"
  }
}