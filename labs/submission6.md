## Task 1

- **Terraform Tool Comparison** - Effectiveness of tfsec vs. Checkov vs. Terrascan
- **Pulumi Security Analysis** - Findings from KICS on Pulumi code
- **Terraform vs. Pulumi** - Compare security issues between declarative HCL and programmatic YAML approaches
- **KICS Pulumi Support** - Evaluate KICS's Pulumi-specific query catalog
- **Critical Findings** - At least 5 significant security issues
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

| Severity | What                                           | Where                                |
| -------- | ---------------------------------------------- | ------------------------------------ |
| INFO     | EC2 Not EBS Optimized                          | ../../src/Pulumi-vulnerable.yaml:157 |
| INFO     | DynamoDB Table Point In Time Recovery Disabled | ../../src/Pulumi-vulnerable.yaml:213 |
| MEDIUM   | RDS DB Instance Publicly Accessible            | ../../src/Pulumi-vulnerable.yaml:104 |
| MEDIUM   | EC2 Instance Monitoring Disabled               | ../../src/Pulumi-vulnerable.yaml:157 |
| HIGH     | Passwords And Secrets - Generic Password       | ../../src/Pulumi-vulnerable.yaml:16  |
| HIGH     | DynamoDB Table Not Encrypted                   | ../../src/Pulumi-vulnerable.yaml:205 |

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
### Tool Strengths

