terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "random_id" "default" {
  byte_length = 8
}

resource "aws_s3_bucket" "default" {
  bucket = "${random_id.default.hex}-terraform-remote-backend"

  tags = {
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_ownership_controls" "default" {
  bucket = aws_s3_bucket.default.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "default" {
  bucket = aws_s3_bucket.default.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "versioning_default" {
  bucket = aws_s3_bucket.default.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "local_file" "default" {
  file_permission = "0644"
  filename        = "${path.module}/backend.tf"
  content         = <<-EOT
  terraform {
    backend "s3" {
      bucket = "${aws_s3_bucket.default.id}"
      key    = "terraform.tfstate"
      region = "eu-central-1"
    }
  }
  EOT
}

