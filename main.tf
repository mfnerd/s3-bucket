provider "aws" {
  region = "us-east-2"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket-o-gold"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}
