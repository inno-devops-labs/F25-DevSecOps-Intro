# Vulnerable Infrastructure-as-Code for Lab 6

⚠️ **WARNING: This directory contains intentionally vulnerable code for educational purposes only!**

## Overview

This directory contains deliberately insecure Terraform, Pulumi, and Ansible code designed for Lab 6 - Infrastructure-as-Code Security. Students will use security scanning tools to identify and understand these vulnerabilities.

## ⚠️ DO NOT USE IN PRODUCTION!

**These files contain serious security vulnerabilities and should NEVER be used in real environments.**

---

## 📂 Directory Structure

```
vulnerable-iac/
├── terraform/
│   ├── main.tf              # Public S3 buckets, hardcoded credentials
│   ├── security_groups.tf   # Overly permissive firewall rules
│   ├── database.tf          # Unencrypted databases, weak configurations
│   ├── iam.tf               # Wildcard IAM permissions
│   └── variables.tf         # Insecure default values
├── pulumi/
│   ├── __main__.py          # Python-based infrastructure with 21 security issues
│   ├── Pulumi.yaml          # Config with default secret values
│   ├── Pulumi-vulnerable.yaml  # YAML-based Pulumi manifest (for KICS scanning)
│   └── requirements.txt     # Python dependencies
└── ansible/
    ├── deploy.yml           # Hardcoded secrets, poor practices
    ├── configure.yml        # Weak SSH config, security misconfigurations
    └── inventory.ini        # Credentials in plaintext
```

---

## 🔴 Terraform Vulnerabilities (30 issues)

### Authentication & Credentials
1. Hardcoded AWS access key in provider configuration
2. Hardcoded AWS secret key in provider configuration
9. Hardcoded database password in plain text
30. Hardcoded API key in variables with default value

### Storage Security
2. S3 bucket with public-read ACL
3. S3 bucket without encryption configuration
4. S3 bucket public access block disabled
16. DynamoDB table without encryption

### Network Security
5. Security group allowing all traffic from 0.0.0.0/0
6. SSH (port 22) accessible from anywhere
6. RDP (port 3389) accessible from anywhere
7. MySQL (port 3306) exposed to internet
7. PostgreSQL (port 5432) exposed to internet

### Database Security
8. RDS instance without storage encryption
10. RDS instance publicly accessible
11. RDS backup retention set to 0 (no backups)
12. RDS deletion protection disabled
14. RDS multi-AZ disabled (no high availability)
15. RDS auto minor version upgrade disabled

### IAM & Permissions
18. IAM policy with wildcard (*) actions and resources
19. IAM role with full S3 access on all resources
20. IAM user with inline policy granting excessive permissions
21. IAM access keys created for service account
22. IAM credentials exposed in outputs without sensitive flag
23. IAM policy allowing privilege escalation paths

### Configuration Management
24. No region validation for resource deployment
25. Weak default password in variables
26. Public access enabled by default
27. Encryption disabled by default
28. SSH allowed from anywhere by default
29. Backup retention days set to 0 by default

---

## 🔴 Pulumi Vulnerabilities (21+ issues)

> **Note:** Pulumi code is provided in both Python (`__main__.py`) and YAML (`Pulumi-vulnerable.yaml`) formats. The YAML format is used for KICS scanning, which has first-class Pulumi YAML support.

### Authentication & Credentials  
1. Hardcoded AWS access key in provider
2. Hardcoded AWS secret key in provider  
3. Hardcoded database password in code
4. Hardcoded API key in code
21. Default config values with secrets in Pulumi.yaml

### Storage Security
3. S3 bucket with public-read ACL  
4. S3 bucket without encryption configuration
17. DynamoDB table without server-side encryption  
18. DynamoDB table without point-in-time recovery
19. EBS volume without encryption

### Network Security  
5. Security group allowing all traffic from 0.0.0.0/0
6. SSH and RDP accessible from anywhere

### Database Security
7. RDS instance without storage encryption  
8. RDS instance publicly accessible
9. RDS backup retention set to 0 (no backups)  
10. RDS deletion protection disabled

### IAM & Permissions
11. IAM policy with wildcard (*) actions and resources  
12. IAM role with full S3 access on all resources
16. Lambda function with overly permissive IAM role

### Compute Security  
13. EC2 instance without root volume encryption
14. Secrets exposed in EC2 user data

### Secrets Management
15. Secrets exposed in Pulumi outputs (not marked as secret)

### Logging & Monitoring  
20. CloudWatch log group without retention policy
20. CloudWatch log group without KMS encryption

---

## 🔴 Ansible Vulnerabilities (26 issues)

### Secrets Management
1. Hardcoded database password in playbook vars
2. Hardcoded API key in playbook vars
3. Database connection string with credentials
20. SSL private key in plaintext
38. Global variables with secrets in inventory
41. Production using same credentials as development

### Command Execution
4. Using shell module instead of proper apt module
5. MySQL command with password visible in logs
10. Downloading and executing script without verification
17. Shell command with potential injection vulnerability
32. Using raw module to flush firewall rules

### File Permissions & Access
6. Configuration file with 0777 permissions (world-writable)
7. SSH private key with 0644 permissions (should be 0600)
16. Downloaded file with 0777 permissions

### Authentication & Access Control
21. SELinux disabled
22. Passwordless sudo for all commands
23. SSH PermitRootLogin enabled
23. SSH PasswordAuthentication enabled
23. SSH PermitEmptyPasswords enabled
34. Authorized key added for root user

### Logging & Monitoring
5. Sensitive command without no_log flag
13. Password hashing without no_log
14. Debug output exposing secrets
18. Password visible in task name
26. Passwords logged in plaintext files

### Network Security
9. Firewall (ufw) disabled
25. Application listening on 0.0.0.0 (all interfaces)

### Credential Management
11. Git credentials hardcoded in repository URL
35. Credentials in inventory file
36. Using root user with password authentication
37. SSH private key path in plaintext inventory

### Configuration Security
15. Using 'latest' instead of pinned versions
24. Installing unnecessary development tools on production
28. Insecure temp file handling with predictable names
29. No timeout for long-running tasks
31. Fetching sensitive files without encryption
33. No checksum validation for templates
39. Insecure SSH connection settings (StrictHostKeyChecking=no)
40. No connection timeout configured

### Error Handling
12. Ignoring errors for critical database migrations
30. No proper error handling in assertions

---

## 🛠️ Tools to Use

Students should scan this code with:

### Terraform
- **tfsec**: Fast Terraform security scanner
- **Checkov**: Policy-as-code security scanner
- **Terrascan**: OPA-based compliance scanner

### Pulumi
- **KICS (Checkmarx)**: Open-source scanner with first-class Pulumi YAML support
  - Dedicated Pulumi queries catalog (AWS/Azure/GCP/Kubernetes)
  - Auto-detects Pulumi platform
  - Provides comprehensive security analysis

### Ansible
- **KICS (Checkmarx)**: Open-source scanner with comprehensive Ansible security queries
  - Dedicated Ansible queries catalog
  - Auto-detects Ansible playbooks
  - Provides comprehensive security analysis

### Policy-as-Code
- **Conftest/OPA**: Custom policy enforcement for all IaC types

---

## 📋 Expected Student Outcomes

Students should:
1. Identify all 80+ security vulnerabilities across Terraform, Pulumi, and Ansible code
   - Note: Pulumi code includes both Python and YAML formats for comprehensive analysis
2. Compare detection capabilities of different tools
3. Compare security issues between declarative (Terraform HCL) and programmatic (Pulumi Python/YAML) IaC
4. Evaluate KICS's first-class Pulumi support and query catalog
5. Understand false positives vs true positives
6. Write custom policies to catch organizational-specific issues
7. Provide remediation steps for each vulnerability class
8. Recommend tool selection strategies for CI/CD pipelines

---

## 🔧 How to Use (Students)

```bash
# Copy vulnerable code to your lab directory
cp -r vulnerable-iac/terraform/* labs/lab6/terraform/
cp -r vulnerable-iac/pulumi/* labs/lab6/pulumi/
cp -r vulnerable-iac/ansible/* labs/lab6/ansible/

# Scan with multiple tools (see lab6.md for commands)
docker run --rm -v "$(pwd)/labs/lab6/terraform":/src aquasec/tfsec:latest /src
docker run --rm -v "$(pwd)/labs/lab6/terraform":/tf bridgecrew/checkov:latest -d /tf
docker run -t --rm -v "$(pwd)/labs/lab6/pulumi":/src checkmarx/kics:latest scan -p /src -o /src/kics-report --report-formats json,html
# ... and more
```

---

## 📚 Learning Resources

- [OWASP Infrastructure as Code Security](https://owasp.org/www-project-devsecops/)
- [Terraform Security Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [Pulumi Security Best Practices](https://www.pulumi.com/docs/guides/crossguard/)
- [Ansible Security Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- [CIS Distribution Independent Linux Benchmark](https://www.cisecurity.org/benchmark/distribution_independent_linux)

---

## 🔒 Security Notice

**These files are for educational purposes only. They contain intentional security vulnerabilities that would compromise real systems. Never deploy this code to any environment connected to the internet or containing real data.**

---

## ✅ Validation

To verify students have completed the lab successfully, check that they:
- [ ] Identified at least 20 Terraform vulnerabilities
- [ ] Identified at least 15 Pulumi vulnerabilities
- [ ] Identified at least 15 Ansible vulnerabilities
- [ ] Compared at least 4 scanning tools (tfsec, Checkov for Terraform, KICS for Pulumi, Terrascan, ansible-lint)
- [ ] Analyzed differences between Terraform (HCL) and Pulumi (Python/YAML) security issues
- [ ] Evaluated KICS's Pulumi-specific query catalog and platform support
- [ ] Created at least 3 custom OPA policies
- [ ] Provided remediation guidance
- [ ] Explained tool selection rationale

---

*Lab created for F25-DevSecOps-Intro course*
