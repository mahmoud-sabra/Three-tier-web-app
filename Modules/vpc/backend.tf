terraform {
  backend "s3" {
    bucket         = "sabratfstatebucket"
    key            = "terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "my_table"

  }
}