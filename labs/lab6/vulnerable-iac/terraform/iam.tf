# Vulnerable IAM Configuration for Lab 6
# Contains overly permissive IAM policies

# IAM policy with wildcard permissions - SECURITY ISSUE #18
resource "aws_iam_policy" "admin_policy" {
  name        = "overly-permissive-policy"
  description = "Policy with wildcard permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "*"  # All actions allowed!
        Resource = "*"  # On all resources!
      }
    ]
  })
}

# IAM role with full S3 access - SECURITY ISSUE #19
resource "aws_iam_role" "app_role" {
  name = "application-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_full_access" {
  name = "s3-full-access"
  role = aws_iam_role.app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*"  # All S3 actions!
        ]
        Resource = "*"  # On all buckets!
      }
    ]
  })
}

# IAM user with inline policy - SECURITY ISSUE #20
resource "aws_iam_user" "service_account" {
  name = "service-account"
  path = "/system/"

  tags = {
    Name = "Service Account"
  }
}

resource "aws_iam_user_policy" "service_policy" {
  name = "service-inline-policy"
  user = aws_iam_user.service_account.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",  # Full EC2 access
          "s3:*",   # Full S3 access
          "rds:*"   # Full RDS access
        ]
        Resource = "*"
      }
    ]
  })
}

# Access key for IAM user - SECURITY ISSUE #21
resource "aws_iam_access_key" "service_key" {
  user = aws_iam_user.service_account.name
}

# Output sensitive data - SECURITY ISSUE #22
output "access_key_id" {
  value = aws_iam_access_key.service_key.id
  # Should be marked as sensitive!
}

output "secret_access_key" {
  value = aws_iam_access_key.service_key.secret
  # Exposing secret key in output!
}

# IAM policy allowing privilege escalation - SECURITY ISSUE #23
resource "aws_iam_policy" "privilege_escalation" {
  name        = "potential-privilege-escalation"
  description = "Policy that allows privilege escalation"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreatePolicy",
          "iam:CreateUser",
          "iam:AttachUserPolicy",
          "iam:AttachRolePolicy",
          "iam:PutUserPolicy",
          "iam:PutRolePolicy"
        ]
        Resource = "*"
      }
    ]
  })
}
