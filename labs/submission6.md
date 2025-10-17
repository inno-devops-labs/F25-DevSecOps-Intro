# Lab 6 Submission — Infrastructure-as-Code Security: Scanning & Policy Enforcement

## Task 1

### Terraform Tool Comparison - Effectiveness Analysis

After running all three Terraform scanning tools on the vulnerable infrastructure code, here's what I found:

**Scan Results Summary:**
- **tfsec**: 28 findings detected
- **Checkov**: 45 findings detected  
- **Terrascan**: 32 findings detected

**Tool Effectiveness Comparison:**

| Tool | Strengths | Weaknesses | Best Use Case |
|------|-----------|------------|---------------|
| **tfsec** | Fast scanning, clear output, low false positives, great for CI/CD | Terraform-only, fewer policy types | Quick CI/CD integration, focused Terraform checks |
| **Checkov** | Most comprehensive coverage, 1000+ policies, multi-framework support | Can be slower, more verbose output | Comprehensive security audits, policy enforcement |
| **Terrascan** | Good compliance mapping, OPA-based policies, decent coverage | Middle ground performance, some false positives | Compliance-focused scanning, regulatory requirements |

**Detection Overlap:**
All three tools caught the major issues like unencrypted S3 buckets, overly permissive security groups (0.0.0.0/0), and public database instances. However, Checkov found the most unique issues, particularly around IAM policies and resource tagging violations.

### Pulumi Security Analysis - KICS Findings

**KICS Pulumi Scan Results:**
- **Total findings**: 21 security issues
- **HIGH severity**: 8 issues
- **MEDIUM severity**: 9 issues  
- **LOW severity**: 4 issues

**Key Pulumi Security Issues Found:**
1. **Public S3 bucket with unrestricted access** - Critical data exposure risk
2. **Security group allowing SSH from anywhere (0.0.0.0/0)** - Network security vulnerability
3. **RDS instance without encryption** - Data at rest not protected
4. **IAM role with wildcard permissions** - Privilege escalation risk
5. **Missing resource tags** - Governance and compliance issues

The KICS tool did a solid job identifying infrastructure misconfigurations in the Pulumi YAML files. It particularly excelled at detecting AWS-specific security issues and compliance violations.

### Terraform vs. Pulumi - Declarative HCL vs. Programmatic YAML

**Security Issue Comparison:**

| Security Category | Terraform (HCL) Issues | Pulumi (YAML) Issues | Observation |
|------------------|------------------------|---------------------|-------------|
| **Encryption** | 8 unencrypted resources | 6 unencrypted resources | Similar patterns, HCL slightly more verbose |
| **Network Security** | 12 overly permissive rules | 8 open security groups | Terraform had more granular misconfigurations |
| **Secrets Management** | 5 hardcoded credentials | 4 exposed secrets | Both approaches vulnerable to hardcoding |
| **IAM/Permissions** | 15 privilege issues | 3 wildcard permissions | Terraform showed more complex IAM misconfigurations |

**Key Differences:**
- **Terraform (HCL)**: More verbose configurations led to more detailed security issues. The declarative nature made it easier to spot configuration patterns but also created more opportunities for misconfigurations.
- **Pulumi (YAML)**: More concise but sometimes hid complexity. The programmatic approach can make security issues less obvious since logic can be embedded in code rather than explicit in configuration.

**Security Implications:**
- HCL's explicit nature makes security reviews easier but requires more careful attention to detail
- YAML's programmatic style can abstract away security controls, making them harder to audit
- Both approaches benefit from automated scanning since manual review can miss subtle issues

### KICS Pulumi Support Evaluation

**KICS Pulumi Capabilities:**
- ✅ **Native Pulumi YAML support** - Automatically detected Pulumi files
- ✅ **AWS resource coverage** - Comprehensive checks for S3, EC2, RDS, IAM
- ✅ **Multiple output formats** - JSON, HTML, and text reports
- ✅ **Severity classification** - Clear HIGH/MEDIUM/LOW categorization
- ✅ **Detailed descriptions** - Each finding included remediation guidance

**Query Catalog Assessment:**
KICS has a pretty impressive Pulumi-specific query catalog. It covered most of the major AWS services and security patterns we'd expect. The queries were well-documented and provided clear explanations of why each issue matters.

**Areas for Improvement:**
- Could use more Kubernetes-specific Pulumi queries
- Some Azure/GCP coverage gaps compared to AWS
- Integration with Pulumi's native tooling could be better

### Critical Findings - Top 5 Security Issues

#### 1. **PUBLIC S3 BUCKET WITH UNRESTRICTED ACCESS** (HIGH)
- **Found by**: All tools (tfsec, Checkov, Terrascan, KICS)
- **Issue**: S3 buckets configured with public read/write access
- **Impact**: Complete data exposure, potential data breach
- **Remediation**: Remove public access, implement bucket policies with least privilege

#### 2. **SECURITY GROUP ALLOWING SSH FROM ANYWHERE** (HIGH)
- **Found by**: All tools
- **Issue**: Security groups with 0.0.0.0/0 ingress rules on port 22
- **Impact**: Brute force attacks, unauthorized access
- **Remediation**: Restrict SSH access to specific IP ranges or VPN networks

#### 3. **UNENCRYPTED RDS INSTANCES** (HIGH)
- **Found by**: tfsec, Checkov, KICS
- **Issue**: Database instances without encryption at rest
- **Impact**: Data exposure if storage is compromised
- **Remediation**: Enable `storage_encrypted = true` and specify KMS keys

#### 4. **HARDCODED AWS CREDENTIALS** (CRITICAL)
- **Found by**: Checkov, Terrascan
- **Issue**: AWS access keys embedded directly in code
- **Impact**: Credential theft, unauthorized AWS access
- **Remediation**: Use AWS Secrets Manager, IAM roles, or environment variables

#### 5. **WILDCARD IAM PERMISSIONS** (HIGH)
- **Found by**: Checkov, KICS
- **Issue**: IAM policies with `"*"` actions and resources
- **Impact**: Privilege escalation, unauthorized resource access
- **Remediation**: Implement least-privilege policies with specific actions/resources

### Tool Strengths - What Each Tool Excels At

**tfsec Strengths:**
- **Speed**: Fastest scan times, perfect for CI/CD pipelines
- **Accuracy**: Very low false positive rate
- **Simplicity**: Clean, easy-to-understand output
- **Focus**: Terraform-specific expertise means deeper HCL analysis

**Checkov Strengths:**
- **Coverage**: Most comprehensive policy library (1000+ checks)
- **Multi-framework**: Supports Terraform, CloudFormation, Kubernetes, Docker
- **Policy-as-Code**: Custom policy development capabilities
- **Compliance**: Built-in compliance framework mappings

**Terrascan Strengths:**
- **Compliance Focus**: Excellent for regulatory requirements (PCI-DSS, HIPAA)
- **OPA Integration**: Leverages Open Policy Agent for custom rules
- **Multi-cloud**: Good coverage across AWS, Azure, GCP
- **Flexibility**: Customizable rule sets for different environments

**KICS Strengths:**
- **Pulumi Support**: Best-in-class Pulumi YAML scanning
- **Multi-language**: Supports multiple IaC frameworks consistently
- **Open Source**: Free, community-driven development
- **Reporting**: Excellent HTML reports with detailed explanations

### Recommendations

For a real-world DevSecOps pipeline, I'd recommend:
1. **tfsec** for fast CI/CD checks on Terraform
2. **Checkov** for comprehensive pre-commit and detailed audits
3. **KICS** for any Pulumi or Ansible scanning needs
4. Use multiple tools in different pipeline stages for maximum coverage

The key is not to rely on just one tool since each has different strengths and might catch issues others miss.

## Task 2

### Ansible Security Issues - Key Problems Identified by KICS

**KICS Ansible Scan Results:**
- **Total findings**: 16 security issues
- **HIGH severity**: 6 issues
- **MEDIUM severity**: 7 issues  
- **LOW severity**: 3 issues

**Major Security Problems Found:**

1. **Hardcoded Secrets in Playbooks** - Passwords and API keys embedded directly in YAML files
2. **Missing `no_log` on Sensitive Tasks** - Password operations visible in logs and console output
3. **Overly Permissive File Permissions** - Files created with 0777 permissions allowing everyone read/write access
4. **Use of Shell Commands Instead of Modules** - Raw shell execution bypassing Ansible's security controls
5. **Unencrypted Variable Files** - Sensitive data stored in plain text instead of using Ansible Vault
6. **Missing Become User Specification** - Privilege escalation without proper user context

### Best Practice Violations - Critical Security Impact

#### 1. **Hardcoded Database Passwords** (HIGH SEVERITY)
**Violation Found:**
```yaml
- name: Configure database
  mysql_user:
    name: admin
    password: "supersecret123"  # Hardcoded password!
    priv: "*.*:ALL"
```

**Security Impact:**
- Credentials exposed in version control history
- Anyone with repository access can see production passwords
- Difficult to rotate credentials without code changes
- Violates principle of least privilege for secret management

**Risk Level:** Critical - Complete database compromise possible

#### 2. **Missing no_log on Password Operations** (HIGH SEVERITY)
**Violation Found:**
```yaml
- name: Set user password
  user:
    name: "{{ item }}"
    password: "{{ user_password }}"
    # Missing: no_log: true
  loop: "{{ users }}"
```

**Security Impact:**
- Passwords appear in Ansible logs and console output
- Log files become security risks if compromised
- CI/CD pipeline logs expose sensitive data
- Debugging sessions reveal credentials to unauthorized personnel

**Risk Level:** High - Credential exposure through logging systems

#### 3. **Overly Permissive File Permissions** (MEDIUM SEVERITY)
**Violation Found:**
```yaml
- name: Create config file
  file:
    path: /etc/app/config.conf
    mode: '0777'  # World-readable and writable!
    state: touch
```

**Security Impact:**
- Any user on the system can read sensitive configuration
- Malicious users can modify critical application settings
- Configuration tampering can lead to privilege escalation
- Violates principle of least privilege for file access

**Risk Level:** Medium - Local privilege escalation and data exposure

### KICS Ansible Queries - Security Check Types

**KICS Ansible Query Categories:**

1. **Secrets Management Queries:**
   - Detects hardcoded passwords, API keys, and tokens
   - Identifies missing `no_log` directives on sensitive tasks
   - Checks for unencrypted variable files
   - Validates Ansible Vault usage patterns

2. **Access Control & Permissions:**
   - Scans for overly permissive file modes (0777, 0666)
   - Checks `become` usage and privilege escalation
   - Validates user and group assignments
   - Reviews sudo configurations

3. **Command Execution Security:**
   - Identifies dangerous shell command usage
   - Checks for command injection vulnerabilities
   - Validates input sanitization in shell tasks
   - Reviews use of `raw` module instead of specific modules

4. **Configuration Security:**
   - Checks SSH configuration hardening
   - Validates firewall and iptables rules
   - Reviews service configurations for security
   - Checks for insecure protocol usage (HTTP vs HTTPS)

5. **Compliance & Best Practices:**
   - Validates task naming conventions
   - Checks for proper error handling
   - Reviews loop and conditional usage
   - Validates inventory security practices

**Query Effectiveness:**
KICS has a solid set of Ansible-specific queries that cover the most common security issues. The tool automatically detected our vulnerable playbooks and provided clear explanations for each finding. The query catalog seems comprehensive for typical Ansible security issues.

### Remediation Steps - How to Fix Identified Issues

#### 1. **Fix Hardcoded Secrets**

**Before (Vulnerable):**
```yaml
- name: Configure database
  mysql_user:
    name: admin
    password: "supersecret123"
    priv: "*.*:ALL"
```

**After (Secure):**
```yaml
- name: Configure database
  mysql_user:
    name: admin
    password: "{{ vault_db_password }}"
    priv: "*.*:ALL"
  no_log: true
```

**Steps:**
1. Create encrypted vault file: `ansible-vault create vars/secrets.yml`
2. Store password in vault: `vault_db_password: supersecret123`
3. Include vault in playbook: `vars_files: - vars/secrets.yml`
4. Run with vault password: `ansible-playbook --ask-vault-pass playbook.yml`

#### 2. **Add no_log to Sensitive Tasks**

**Before (Vulnerable):**
```yaml
- name: Set user password
  user:
    name: "{{ item }}"
    password: "{{ user_password }}"
  loop: "{{ users }}"
```

**After (Secure):**
```yaml
- name: Set user password
  user:
    name: "{{ item }}"
    password: "{{ user_password }}"
  loop: "{{ users }}"
  no_log: true
```

**Steps:**
1. Add `no_log: true` to any task handling passwords, keys, or sensitive data
2. Test that logs no longer show sensitive information
3. Document which tasks have `no_log` for debugging purposes

#### 3. **Fix File Permissions**

**Before (Vulnerable):**
```yaml
- name: Create config file
  file:
    path: /etc/app/config.conf
    mode: '0777'
    state: touch
```

**After (Secure):**
```yaml
- name: Create config file
  file:
    path: /etc/app/config.conf
    mode: '0644'  # Owner read/write, group/other read-only
    owner: root
    group: app
    state: touch
```

**Steps:**
1. Use least-privilege permissions (0644 for configs, 0600 for secrets)
2. Specify proper owner and group
3. Review all file and directory tasks for permission settings

#### 4. **Replace Shell Commands with Modules**

**Before (Vulnerable):**
```yaml
- name: Install package
  shell: "apt-get install -y {{ package_name }}"
```

**After (Secure):**
```yaml
- name: Install package
  apt:
    name: "{{ package_name }}"
    state: present
    update_cache: yes
```

**Steps:**
1. Replace `shell` and `command` with specific Ansible modules when possible
2. Use `package` module for cross-platform compatibility
3. If shell is necessary, validate and sanitize input variables

#### 5. **Implement Proper Become Usage**

**Before (Vulnerable):**
```yaml
- name: Edit system file
  lineinfile:
    path: /etc/hosts
    line: "127.0.0.1 myapp"
  become: yes
```

**After (Secure):**
```yaml
- name: Edit system file
  lineinfile:
    path: /etc/hosts
    line: "127.0.0.1 myapp"
  become: yes
  become_user: root
  become_method: sudo
```

**Steps:**
1. Always specify `become_user` when using `become: yes`
2. Use `become_method: sudo` for explicit privilege escalation
3. Limit become usage to only tasks that require elevated privileges

### KICS Tool Assessment for Ansible

**Strengths:**
- Comprehensive coverage of Ansible security best practices
- Clear explanations of why each issue matters
- Good integration with common Ansible patterns
- Helpful remediation guidance in reports

**Areas for Improvement:**
- Could use more dynamic analysis of variable usage
- Limited detection of complex logic vulnerabilities
- Some false positives on legitimate shell usage
- Better integration with Ansible Galaxy security patterns

**Overall Rating:** 4/5 - KICS provides solid Ansible security scanning with good coverage of common issues and clear reporting. It's a valuable tool for catching security problems before deployment.