# Vulnerable Variables Configuration for Lab 6
# Contains insecure default values

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
  # No validation for approved regions - SECURITY ISSUE #24
}

variable "db_password" {
  description = "Database password"
  type        = string
  default     = "changeme123"  # SECURITY ISSUE #25 - Weak default password!
  # Should not have a default value for passwords!
  # Should be marked as sensitive!
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"  # Defaulting to production is risky
  # No validation
}

variable "enable_public_access" {
  description = "Enable public access to resources"
  type        = bool
  default     = true  # SECURITY ISSUE #26 - Public access enabled by default!
}

variable "enable_encryption" {
  description = "Enable encryption"
  type        = bool
  default     = false  # SECURITY ISSUE #27 - Encryption disabled by default!
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed for SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # SECURITY ISSUE #28 - Allows SSH from anywhere!
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 0  # SECURITY ISSUE #29 - No backups by default!
}

variable "api_key" {
  description = "API key for external service"
  type        = string
  default     = "sk_test_1234567890abcdef"  # SECURITY ISSUE #30 - Hardcoded API key!
  # Should not have default, should be sensitive
}

# No validation constraints on critical variables
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
  # No validation - could use expensive instance types
}

variable "allowed_regions" {
  description = "List of allowed AWS regions"
  type        = list(string)
  default     = ["us-east-1", "us-west-2", "eu-west-1"]
  # Not enforced anywhere in the code
}

# Missing required variables
# - No variable for required resource tags
# - No variable for KMS key IDs
# - No variable for logging configuration
