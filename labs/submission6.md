# Lab 6 Submission - Infrastructure-as-Code Security: Scanning & Policy Enforcement

## Task 1 — Terraform & Pulumi Security Scanning

### Terraform Tool Comparison

Based on the scanning results, here's the comparative analysis of Terraform security tools:

| Tool | Findings | Scan Speed | False Positives | Report |Platform Support |
|------|----------|------------|-----------------|----------------|-----------------|
| **tfsec** | 53 | Fast | Very Low | Low| Terraform only |
| **Checkov** | 78 | Medium | Low | Medium | Multiple frameworks |
| **Terrascan** | 22 | Slow | Medium | High | Multiple frameworks |




#### Tool Effectiveness Analysis

**tfsec (53 findings):**
- **Strengths**: Fast execution, Terraform-specific optimizations, comprehensive AWS coverage
- **Weaknesses**: Limited to Terraform only
- **Best For**: Fast CI/CD scans, Terraform-specific projects

**Checkov (78 findings):**
- **Strengths**: Most comprehensive coverage, extensive policy library (1000+ policies), multi-framework support
- **Weaknesses**: Higher false positive rate, slower execution
- **Best For**: Enterprise environments requiring comprehensive coverage

**Terrascan (22 findings):**
- **Strengths**: OPA-based policies, compliance framework mapping, low false positives
- **Weaknesses**: Fewer findings than competitors, limited policy scope
- **Best For**: Compliance-focused scanning, organizations using OPA

### Pulumi Security Analysis (KICS)

KICS identified **6 security issues** in the Pulumi YAML configuration:

#### Findings from Pulumi Scan:

1. **Passwords And Secrets - Generic Password** 🔴 HIGH
   - **Location**: `Pulumi-vulnerable.yaml:16`

2. **DynamoDB Table Not Encrypted** 🔴 HIGH
   - **Location**: `Pulumi-vulnerable.yaml:205`

3. **RDS DB Instance Publicly Accessible** 🟡 MEDIUM
   - **Location**: `Pulumi-vulnerable.yaml:104`

4. **EC2 Instance Monitoring Disabled** 🟡 MEDIUM
   - **Location**: `Pulumi-vulnerable.yaml:157`

### Terraform vs. Pulumi Security Comparison

| Aspect | Terraform (HCL) | Pulumi (YAML/Python) |
|--------|-----------------|---------------------|
| **Security Tool Support** | Extensive (tfsec, Checkov, Terrascan) | Limited (primarily KICS) |
| **Finding Density** | High (53-78 findings) | Moderate (6 findings) |
| **Common Issues** | IAM policies, encryption, network security | Credentials, encryption, monitoring |

### KICS Pulumi Support Evaluation

KICS demonstrates **adequate Pulumi support** with:
- **Coverage**: Basic AWS resource security checks
- **Limitations**: Limited to YAML-based Pulumi configurations
- **Effectiveness**: Good at identifying critical security issues
- **Recommendation**: Suitable for basic Pulumi security scanning but needs expansion

## Critical Findings - 5 Significant Security Issues

### 1. **Hardcoded AWS Credentials**
- **Tool**: Checkov
- **Location**: `main.tf:5-10`

### 2. **Publicly Accessible RDS Instance**
- **Tool**: Terrascan & KICS
- **Location**: `database.tf:5` & `Pulumi-vulnerable.yaml:104`

### 3. **Unencrypted DynamoDB Table**
- **Tool**: KICS
- **Location**: `Pulumi-vulnerable.yaml:205`

### 4. **Overly Permissive Security Group**
- **Tool**: tfsec & Checkov
- **Location**: `security_groups.tf:5-28`

### 5. **Plaintext Passwords in Ansible**
- **Tool**: KICS
- **Location**: `inventory.ini` multiple lines

## Tool Strengths

### tfsec
- **Fast scanning with low false positives**
- **Terraform-specific optimizations**

### Checkov
- **Comprehensive coverage (1000+ policies)**

### Terrascan
- **Infrastructure dependency analysis**

### KICS
- **Multi-language support (Terraform, Pulumi, Ansible)**

## Task 2 — Ansible Security Scanning with KICS

### Ansible Security Issues

KICS identified **9 security issues** in Ansible playbooks, with **8 HIGH severity** findings:

#### Critical Ansible Findings:

1. **Passwords And Secrets - Password in URL**  HIGH (2 instances)
   - **Location**: `deploy.yml:72,16`

2. **Passwords And Secrets - Generic Password**  HIGH (6 instances)
   - **Locations**: Multiple files including `inventory.ini` and `configure.yml`

3. **Unpinned Package Version**  LOW
   - **Location**: `deploy.yml:99`

### Best Practice Violations

1. **Secrets Management**
   - **Violation**: Hardcoded credentials in inventory files and playbooks
   - **Security Impact**: Credential theft, unauthorized access
   - **Remediation**: Implement Ansible Vault for all secrets

2. **Configuration Security**
   - **Violation**: Plaintext passwords in configuration files
   - **Security Impact**: Information disclosure, privilege escalation
   - **Remediation**: Use environment variables or encrypted storage

3. **Package Management**
   - **Violation**: Unpinned package versions
   - **Security Impact**: Inconsistent deployments, vulnerable dependencies
   - **Remediation**: Pin all package versions to specific releases

### KICS Ansible Queries Evaluation

KICS provides **comprehensive Ansible security coverage**:
- **Secret Detection**: Effective at identifying hardcoded credentials
- **Configuration Checks**: Basic security configuration validation
- **Limitations**: Limited to common patterns, may miss complex logic issues

## Task 3 — Comparative Tool Analysis & Security Insights

### Comprehensive Tool Comparison Matrix

| Criterion | tfsec | Checkov | Terrascan | KICS |
|-----------|-------|---------|-----------|------|
| **Total Findings** | 53 | 78 | 22 | 15 (Pulumi + Ansible) |
| **Scan Speed** | Fast | Medium | Fast | Medium |
| **False Positives** | Very Low | Low | Medium | Low |
| **Report Quality** | 1 | 2 | 3 | 4 |
| **Platform Support** | Terraform only | Multiple | Multiple | Multiple |

### Vulnerability Category Analysis

| Security Category | tfsec | Checkov | Terrascan | KICS (Pulumi) | KICS (Ansible) | Best Tool |
|------------------|-------|---------|-----------|---------------|----------------|----------|
| **Encryption Issues** | High | High | Medium | High | N/A | Checkov |
| **Network Security** | High | High | High | Medium | N/A | Checkov |
| **Secrets Management** | Medium | High | Medium | High | High | Checkov |
| **IAM/Permissions** | High | High | Medium | Low | N/A | Checkov |
| **Access Control** | High | High | High | Medium | N/A | Checkov |
| **Compliance/Best Practices** | Medium | High | High | Medium | Medium | Checkov |

### Top 5 Critical Findings

1. **Hardcoded AWS Credentials** 
   - **Tool**: Checkov
   - **Location**: `main.tf:5-10`
   - **Remediation**:
     ```terraform
     # Remove hardcoded credentials
     # Use environment variables or IAM roles
     provider "aws" {
       region = var.region
     }
     ```

2. **Publicly Accessible RDS Instance**  HIGH
   - **Tool**: Terrascan
   - **Location**: `database.tf:5`
   - **Remediation**:
     ```terraform
     resource "aws_db_instance" "secure_db" {
       publicly_accessible = false
       # ... other configuration
     }
     ```

3. **Unencrypted DynamoDB Table**  HIGH
   - **Tool**: KICS (Pulumi)
   - **Location**: `Pulumi-vulnerable.yaml:205`
   - **Remediation**:
     ```yaml
     resources:
       encryptedTable:
         type: aws:dynamodb:Table
         properties:
           serverSideEncryption:
             enabled: true
     ```

4. **Overly Permissive Security Group**  HIGH
   - **Tool**: tfsec
   - **Location**: `security_groups.tf:5-28`
   - **Remediation**:
     ```terraform
     resource "aws_security_group" "restricted" {
       ingress {
         from_port   = 22
         to_port     = 22
         protocol    = "tcp"
         cidr_blocks = ["10.0.0.0/16"] # Restrict to VPC
       }
     }
     ```

5. **Plaintext Passwords in Ansible**  HIGH
   - **Tool**: KICS (Ansible)
   - **Location**: Multiple files
   - **Remediation**:
     ```yaml
     # Use Ansible Vault
     ansible-vault encrypt_string 'mysecretpassword' --name 'db_password'
     ```

### Tool Selection Guide

**For Small Teams/Startups:**
- **Primary**: tfsec (fast, low false positives)
- **Secondary**: KICS (multi-language support)
- **Rationale**: Balance of speed and coverage

**For Enterprise Organizations:**
- **Primary**: Checkov (comprehensive coverage)
- **Secondary**: Terrascan (compliance focus)
- **Rationale**: Maximum security coverage

**For Multi-Framework Environments:**
- **Primary**: KICS (consistent across Terraform, Pulumi, Ansible)
- **Secondary**: Checkov (Terraform depth)
- **Rationale**: Unified security approach

### Lessons Learned

1. **Tool Diversity Matters**: No single tool catches all issues; use multiple scanners
2. **False Positive Management**: Checkov found most issues but had higher false positives
3. **Framework Maturity**: Terraform has superior tooling compared to Pulumi
4. **Secret Management**: Universal problem across all IaC frameworks
5. **Compliance Focus**: Different tools excel in different security domains

### CI/CD Integration Strategy

#### Multi-Stage Pipeline Implementation:

```yaml
stages:
  - test
  - security-scan
  - deploy

security-scan:
  stage: security-scan
  parallel:
    - terraform-tfsec:
        script:
          - docker run --rm -v "$(pwd):/src" aquasec/tfsec:latest /src
    - terraform-checkov:
        script:
          - docker run --rm -v "$(pwd):/tf" bridgecrew/checkov:latest -d /tf
    - multi-framework-kics:
        script:
          - docker run --rm -v "$(pwd):/src" checkmarx/kics:latest scan -p /src
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"