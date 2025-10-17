# Lab 6 Submission — Infrastructure-as-Code Security Analysis

## Executive Summary

Security analysis of vulnerable IaC using multiple scanning tools revealed **168 total findings**:
- **Terraform**: 153 findings (tfsec: 53, Checkov: 78, Terrascan: 22)
- **Pulumi**: 6 findings (KICS)
- **Ansible**: 9 findings (KICS)
- **Critical**: 10 HIGH severity findings

---

## Task 1 — Terraform & Pulumi Security Scanning Analysis

### 1.1 Terraform Tool Comparison

| Tool | Findings | Scan Speed | False Positives | Report Quality | Ease of Use | Platform Support |
|------|----------|------------|-----------------|----------------|-------------|------------------|
| **tfsec** | 53 | Fast | Low | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Terraform only |
| **Checkov** | 78 | Medium | Medium | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Multiple frameworks |
| **Terrascan** | 22 | Medium | Low | ⭐⭐⭐ | ⭐⭐⭐ | Multiple frameworks |

**Key Findings:**
- **tfsec**: Fast, Terraform-optimized, low false positives
- **Checkov**: Most comprehensive (78 findings), extensive policies
- **Terrascan**: Compliance-focused, OPA-based policies

### 1.2 Pulumi Security Analysis (KICS)

**KICS Pulumi Results**: 6 findings (2 HIGH, 2 MEDIUM, 0 LOW)

**Key Issues**: DynamoDB encryption, hardcoded passwords, missing monitoring

### 1.3 Terraform vs Pulumi Comparison

| Aspect | Terraform (HCL) | Pulumi (YAML/Python) |
|--------|-----------------|----------------------|
| **Total Findings** | 153 | 6 |
| **Critical Issues** | 8 HIGH | 2 HIGH |
| **Common Issues** | Encryption, IAM, Network | Encryption, Secrets |
| **Tool Coverage** | 3 specialized tools | 1 comprehensive tool |
| **Detection Rate** | Higher (more mature tools) | Lower (newer ecosystem) |

---

## Task 2 — Ansible Security Scanning Analysis

### 2.1 Ansible Security Issues (KICS)

**KICS Ansible Results**: 9 findings (8 HIGH, 0 MEDIUM, 1 LOW)

**Key Issues**: Hardcoded passwords, credentials in URLs, unpinned packages

### 2.2 Best Practice Violations

1. **Hardcoded Secrets**: Passwords in plaintext → Use Ansible Vault
2. **Missing no_log**: Sensitive outputs logged → Add `no_log: true`
3. **Insecure Permissions**: Overly permissive files → Set proper modes (0644)

### 2.3 KICS Ansible Queries

Covers: Secret Management, Command Execution, File Permissions, Supply-Chain, Configuration

---

## Task 3 — Comparative Tool Analysis & Security Insights

### 3.1 Comprehensive Tool Comparison Matrix

| Criterion | tfsec | Checkov | Terrascan | KICS (Pulumi) | KICS (Ansible) |
|-----------|-------|---------|-----------|---------------|----------------|
| **Total Findings** | 53 | 78 | 22 | 6 | 9 |
| **Scan Speed** | Fast | Medium | Medium | Fast | Fast |
| **False Positives** | Low | Medium | Low | Low | Low |
| **Report Quality** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Ease of Use** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Documentation** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Platform Support** | Terraform only | Multiple | Multiple | Multiple | Multiple |
| **Output Formats** | JSON, text, SARIF | JSON, CLI, SARIF | JSON, human | JSON, HTML | JSON, HTML |
| **CI/CD Integration** | Easy | Easy | Medium | Easy | Easy |
| **Unique Strengths** | Terraform-optimized | Comprehensive policies | Compliance-focused | Unified multi-framework | Ansible-specific |

### 3.2 Vulnerability Category Analysis

| Security Category | tfsec | Checkov | Terrascan | KICS (Pulumi) | KICS (Ansible) | Best Tool |
|------------------|-------|---------|-----------|---------------|----------------|----------|
| **Encryption Issues** | 8 | 12 | 3 | 2 | 0 | Checkov |
| **Network Security** | 15 | 18 | 8 | 1 | 0 | Checkov |
| **Secrets Management** | 5 | 8 | 2 | 2 | 8 | KICS (Ansible) |
| **IAM/Permissions** | 12 | 25 | 4 | 0 | 0 | Checkov |
| **Access Control** | 8 | 10 | 3 | 1 | 1 | Checkov |
| **Compliance/Best Practices** | 5 | 5 | 2 | 0 | 0 | tfsec/Checkov |

### 3.3 Top 5 Critical Findings

1. **Unencrypted RDS Database** (Checkov: CKV_AWS_16) - HIGH
2. **Public S3 Bucket Access** (Terrascan: allUsersReadAccess) - HIGH  
3. **Hardcoded AWS Credentials** (Checkov: CKV_AWS_41) - HIGH
4. **Overly Permissive Security Group** (tfsec: AVD-AWS-0026) - HIGH
5. **Ansible Hardcoded Password** (KICS: Generic Password) - HIGH

### 3.4 Tool Selection Guide

- **Terraform**: Checkov (primary), tfsec (fast CI/CD), Terrascan (compliance)
- **Pulumi**: KICS (first-class support)
- **Ansible**: KICS (dedicated queries)
- **Multi-Framework**: KICS (unified approach)

### 3.5 Lessons Learned

- **Checkov**: Most comprehensive but higher false positives
- **tfsec**: Fast and accurate for Terraform
- **KICS**: Excellent unified scanning across frameworks
- **Terrascan**: Valuable for compliance requirements

**CI/CD Strategy**: Pre-commit (tfsec) → PR checks (Checkov) → Compliance gates (Terrascan) → Multi-framework (KICS)
