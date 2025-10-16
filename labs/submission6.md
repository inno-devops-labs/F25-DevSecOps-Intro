## Task 1

- **Tool Strengths** - What each tool excels at detecting

### Terraform Tool Comparison

| Tool      | # of findings | # of HIGH/CRITICAL findings |
| --------- | ------------- | --------------------------- |
| tfsec     | 53            | 34                          |
| Checkov   | 78            | -                           |
| Terrascan | 22            | 14                          |

We can see that Checkov has reported the most findings, Terrascan has reported the fewest. However, Checkov does not
rank its findings by severity, which makes it difficult to focus on the most critical issues. Tfsec has reported more
HIGH/CRITICAL issues than Terrascan.

### Pulumi Security Analysis

There were 6 findings in total.

| Severity | What                                           | Where                      |
| -------- | ---------------------------------------------- | -------------------------- |
| INFO     | EC2 Not EBS Optimized                          | Pulumi-vulnerable.yaml:157 |
| INFO     | DynamoDB Table Point In Time Recovery Disabled | Pulumi-vulnerable.yaml:213 |
| MEDIUM   | RDS DB Instance Publicly Accessible            | Pulumi-vulnerable.yaml:104 |
| MEDIUM   | EC2 Instance Monitoring Disabled               | Pulumi-vulnerable.yaml:157 |
| HIGH     | Passwords And Secrets - Generic Password       | Pulumi-vulnerable.yaml:16  |
| HIGH     | DynamoDB Table Not Encrypted                   | Pulumi-vulnerable.yaml:205 |

### Terraform vs. Pulumi

These two approaches have essentially the same issues, as shown in comments in the vulnerable configuration files. These
issues include unencrypted and/or publicly accessible data, hardcoded secrets, insecure passwords.

### KICS Pulumi Support

Below are the queries performed on the config file.
- DynamoDB Table Not Encrypted
- Passwords And Secrets - Generic Password
- EC2 Instance Monitoring Disabled
- RDS DB Instance Publicly Accessible
- DynamoDB Table Point In Time Recovery Disabled
- EC2 Not EBS Optimized

### Critical Findings

- Instance is exposed publicly. (database.tf:17)
- Security group rule allows ingress from public internet. (security_groups.tf:15)
- Security group rule allows egress to multiple public internet addresses. (security_groups.tf:22)
- Security group rule allows ingress from public internet. (security_groups.tf:41)
- Security group rule allows ingress from public internet. (security_groups.tf:49)
- Security group rule allows egress to multiple public internet addresses. (security_groups.tf:56)
- Security group rule allows ingress from public internet. (security_groups.tf:75)
- Security group rule allows ingress from public internet. (security_groups.tf:83)
- Security group rule allows egress to multiple public internet addresses. (security_groups.tf:90)

### Tool Strengths

- **tfsec**, **Checkov**: Terraform vulnerabilities
- **Terrascan**: Terraform compliance issues
- **KICS**: Pulumi vulnerabilities


