# Vulnerable Terraform Configuration for Lab 6
# This file contains intentional security issues for educational purposes
# DO NOT use this code in production!

provider "aws" {
  region = "us-east-1"
  # Hardcoded credentials - SECURITY ISSUE #1
  access_key = "AKIAIOSFODNN7EXAMPLE"
  secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
}

# Public S3 bucket - SECURITY ISSUE #2
resource "aws_s3_bucket" "public_data" {
  bucket = "my-public-bucket-lab6"
  acl    = "public-read"  # Public access enabled!

  tags = {
    Name = "Public Data Bucket"
    # Missing required tags: Environment, Owner, CostCenter
  }
}

# S3 bucket without encryption - SECURITY ISSUE #3
resource "aws_s3_bucket" "unencrypted_data" {
  bucket = "my-unencrypted-bucket-lab6"
  acl    = "private"
  
  # No server_side_encryption_configuration!
  
  versioning {
    enabled = false  # Versioning disabled
  }
}

# S3 bucket with public access block disabled - SECURITY ISSUE #4
resource "aws_s3_bucket_public_access_block" "bad_config" {
  bucket = aws_s3_bucket.public_data.id

  block_public_acls       = false  # Should be true
  block_public_policy     = false  # Should be true
  ignore_public_acls      = false  # Should be true
  restrict_public_buckets = false  # Should be true
}
