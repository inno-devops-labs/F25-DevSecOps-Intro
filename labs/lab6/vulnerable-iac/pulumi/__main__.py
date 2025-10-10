"""
Vulnerable Pulumi Infrastructure Code for Lab 6
This file contains intentional security issues for educational purposes
DO NOT use this code in production!

Language: Python
Cloud: AWS
"""

import pulumi
import pulumi_aws as aws

# SECURITY ISSUE #1 - Hardcoded AWS credentials
aws_provider = aws.Provider("aws-provider",
    region="us-east-1",
    access_key="AKIAIOSFODNN7EXAMPLE",  # Hardcoded!
    secret_key="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"  # Hardcoded!
)

# SECURITY ISSUE #2 - Hardcoded secrets in config
config = pulumi.Config()
db_password = "SuperSecret123!"  # Should use config.require_secret()
api_key = "sk_live_1234567890abcdef"  # Hardcoded API key

# SECURITY ISSUE #3 - Public S3 bucket
public_bucket = aws.s3.Bucket("public-bucket",
    bucket="my-public-bucket-pulumi",
    acl="public-read",  # Public access!
    tags={
        "Name": "Public Bucket",
        # Missing required tags: Environment, Owner
    }
)

# SECURITY ISSUE #4 - S3 bucket without encryption
unencrypted_bucket = aws.s3.Bucket("unencrypted-bucket",
    bucket="my-unencrypted-bucket-pulumi",
    acl="private",
    # No server_side_encryption_configuration!
    versioning=aws.s3.BucketVersioningArgs(
        enabled=False  # Versioning disabled
    ),
    tags={
        "Name": "Unencrypted Bucket"
    }
)

# SECURITY ISSUE #5 - Security group allowing all traffic from anywhere
allow_all_sg = aws.ec2.SecurityGroup("allow-all-sg",
    description="Allow all inbound traffic",
    vpc_id="vpc-12345678",
    ingress=[
        aws.ec2.SecurityGroupIngressArgs(
            description="Allow all traffic",
            from_port=0,
            to_port=65535,
            protocol="-1",  # All protocols
            cidr_blocks=["0.0.0.0/0"],  # From anywhere!
        )
    ],
    egress=[
        aws.ec2.SecurityGroupEgressArgs(
            from_port=0,
            to_port=0,
            protocol="-1",
            cidr_blocks=["0.0.0.0/0"],
        )
    ],
    tags={
        "Name": "Allow All Security Group"
    }
)

# SECURITY ISSUE #6 - SSH open to the world
ssh_open_sg = aws.ec2.SecurityGroup("ssh-open-sg",
    description="SSH from anywhere",
    vpc_id="vpc-12345678",
    ingress=[
        aws.ec2.SecurityGroupIngressArgs(
            description="SSH from anywhere",
            from_port=22,
            to_port=22,
            protocol="tcp",
            cidr_blocks=["0.0.0.0/0"],  # SSH from anywhere!
        ),
        aws.ec2.SecurityGroupIngressArgs(
            description="RDP from anywhere",
            from_port=3389,
            to_port=3389,
            protocol="tcp",
            cidr_blocks=["0.0.0.0/0"],  # RDP from anywhere!
        )
    ],
    tags={
        "Name": "SSH Open"
    }
)

# SECURITY ISSUE #7 - Unencrypted RDS instance
unencrypted_db = aws.rds.Instance("unencrypted-db",
    identifier="mydb-unencrypted-pulumi",
    engine="postgres",
    engine_version="13.7",
    instance_class="db.t3.micro",
    allocated_storage=20,
    username="admin",
    password=db_password,  # Hardcoded password from above!
    storage_encrypted=False,  # No encryption!
    publicly_accessible=True,  # SECURITY ISSUE #8 - Public access!
    skip_final_snapshot=True,
    backup_retention_period=0,  # SECURITY ISSUE #9 - No backups!
    deletion_protection=False,  # SECURITY ISSUE #10
    vpc_security_group_ids=[allow_all_sg.id],
    tags={
        "Name": "Unencrypted Database"
    }
)

# SECURITY ISSUE #11 - IAM policy with wildcard permissions
admin_policy = aws.iam.Policy("admin-policy",
    description="Policy with wildcard permissions",
    policy=pulumi.Output.all().apply(lambda _: """{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }]
    }""")
)

# SECURITY ISSUE #12 - IAM role with overly permissive S3 access
app_role = aws.iam.Role("app-role",
    assume_role_policy=pulumi.Output.all().apply(lambda _: """{
        "Version": "2012-10-17",
        "Statement": [{
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            }
        }]
    }""")
)

s3_full_access_policy = aws.iam.RolePolicy("s3-full-access",
    role=app_role.id,
    policy=pulumi.Output.all().apply(lambda _: """{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        }]
    }""")
)

# SECURITY ISSUE #13 - EC2 instance without encryption
unencrypted_instance = aws.ec2.Instance("unencrypted-instance",
    ami="ami-0c55b159cbfafe1f0",
    instance_type="t2.micro",
    vpc_security_group_ids=[ssh_open_sg.id],
    # No root_block_device encryption!
    user_data=f"""#!/bin/bash
    echo "DB_PASSWORD={db_password}" > /etc/app/config  # SECURITY ISSUE #14 - Password in user data!
    echo "API_KEY={api_key}" >> /etc/app/config
    """,
    tags={
        "Name": "Unencrypted Instance"
    }
)

# SECURITY ISSUE #15 - Exposing secrets in outputs (not marked as secret)
pulumi.export("bucket_name", public_bucket.id)
pulumi.export("db_endpoint", unencrypted_db.endpoint)
pulumi.export("db_password", db_password)  # Exposing password!
pulumi.export("api_key", api_key)  # Exposing API key!

# SECURITY ISSUE #16 - Lambda function with overly permissive IAM role
lambda_role = aws.iam.Role("lambda-role",
    assume_role_policy=pulumi.Output.all().apply(lambda _: """{
        "Version": "2012-10-17",
        "Statement": [{
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            }
        }]
    }""")
)

lambda_policy = aws.iam.RolePolicy("lambda-policy",
    role=lambda_role.id,
    policy=pulumi.Output.all().apply(lambda _: """{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Action": [
                "s3:*",
                "dynamodb:*",
                "rds:*",
                "ec2:*"
            ],
            "Resource": "*"
        }]
    }""")
)

# SECURITY ISSUE #17 - DynamoDB table without encryption
unencrypted_table = aws.dynamodb.Table("unencrypted-table",
    name="my-table-pulumi",
    attributes=[
        aws.dynamodb.TableAttributeArgs(
            name="id",
            type="S",
        )
    ],
    hash_key="id",
    billing_mode="PAY_PER_REQUEST",
    # No server_side_encryption!
    point_in_time_recovery=aws.dynamodb.TablePointInTimeRecoveryArgs(
        enabled=False  # SECURITY ISSUE #18 - No PITR
    ),
    tags={
        "Name": "Unencrypted Table"
    }
)

# SECURITY ISSUE #19 - EBS volume without encryption
unencrypted_volume = aws.ebs.Volume("unencrypted-volume",
    availability_zone="us-east-1a",
    size=10,
    encrypted=False,  # No encryption!
    tags={
        "Name": "Unencrypted Volume"
    }
)

# SECURITY ISSUE #20 - CloudWatch log group without retention
log_group = aws.cloudwatch.LogGroup("app-logs",
    name="/aws/app/logs",
    retention_in_days=0,  # Logs never expire - cost and compliance issue
    # No KMS encryption!
)

print(f"⚠️  WARNING: This Pulumi stack contains {20} intentional security vulnerabilities!")
print("   This is for educational purposes only - DO NOT deploy to production!")
