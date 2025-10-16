# Vulnerable Database Configuration for Lab 6
# Contains unencrypted databases and poor security practices

# Unencrypted RDS instance - SECURITY ISSUE #8
resource "aws_db_instance" "unencrypted_db" {
  identifier           = "mydb-unencrypted"
  engine               = "postgres"
  engine_version       = "13.7"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  
  username = "admin"
  password = "SuperSecretPassword123!"  # SECURITY ISSUE #9 - Hardcoded password!
  
  storage_encrypted = false  # No encryption!
  
  publicly_accessible = true  # SECURITY ISSUE #10 - Public access!
  
  skip_final_snapshot = true
  
  # No backup configuration
  backup_retention_period = 0  # SECURITY ISSUE #11 - No backups!
  
  # Missing monitoring
  enabled_cloudwatch_logs_exports = []
  
  # No deletion protection
  deletion_protection = false  # SECURITY ISSUE #12
  
  # Using default security group
  vpc_security_group_ids = [aws_security_group.database_exposed.id]
  
  tags = {
    Name = "Unencrypted Database"
    # Missing required tags
  }
}

# Database with weak configuration - SECURITY ISSUE #13
resource "aws_db_instance" "weak_db" {
  identifier           = "mydb-weak"
  engine               = "mysql"
  engine_version       = "5.7.38"  # Old version with known vulnerabilities
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  
  username = "root"  # Using default admin username
  password = "password123"  # Weak password!
  
  storage_encrypted = true
  kms_key_id        = ""  # Empty KMS key - using default key
  
  publicly_accessible = false
  
  # Multi-AZ disabled
  multi_az = false  # SECURITY ISSUE #14 - No high availability
  
  # Auto minor version upgrade disabled
  auto_minor_version_upgrade = false  # SECURITY ISSUE #15
  
  # No performance insights
  performance_insights_enabled = false
  
  skip_final_snapshot = true
  
  tags = {
    Name = "Weak Database"
  }
}

# DynamoDB table without encryption - SECURITY ISSUE #16
resource "aws_dynamodb_table" "unencrypted_table" {
  name           = "my-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # No server_side_encryption configuration!
  
  # No point-in-time recovery
  point_in_time_recovery {
    enabled = false  # SECURITY ISSUE #17
  }

  tags = {
    Name = "Unencrypted DynamoDB Table"
  }
}
