# Vulnerable Security Groups for Lab 6
# Contains overly permissive network rules

# Security group allowing ALL traffic from anywhere - SECURITY ISSUE #5
resource "aws_security_group" "allow_all" {
  name        = "allow-all-traffic"
  description = "Allow all inbound traffic from anywhere"
  vpc_id      = "vpc-12345678"

  ingress {
    description = "Allow all traffic"
    from_port   = 0
    to_port     = 65535
    protocol    = "-1"  # All protocols
    cidr_blocks = ["0.0.0.0/0"]  # From anywhere!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow All Security Group"
  }
}

# Security group with SSH open to the world - SECURITY ISSUE #6
resource "aws_security_group" "ssh_open" {
  name        = "ssh-from-anywhere"
  description = "SSH access from anywhere"
  vpc_id      = "vpc-12345678"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # SSH from anywhere!
  }

  ingress {
    description = "RDP from anywhere"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # RDP from anywhere!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SSH Open Security Group"
  }
}

# Security group with database ports exposed - SECURITY ISSUE #7
resource "aws_security_group" "database_exposed" {
  name        = "database-public"
  description = "Database accessible from internet"
  vpc_id      = "vpc-12345678"

  ingress {
    description = "MySQL from anywhere"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Database exposed!
  }

  ingress {
    description = "PostgreSQL from anywhere"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Database exposed!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
