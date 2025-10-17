# Lab 6 — Infrastructure-as-Code Security: Scanning & Policy Enforcement

## Task 1 — Terraform & Pulumi Security Scanning

### 1.1 Terraform Tool Comparison — tfsec vs Checkov vs Terrascan

Each Terraform IaC security tool provided complementary detection results when scanning vulnerable infrastructure.

| Tool      | Findings Count | Severity Breakdown | Key Issues Detected |
|------------|----------------|--------------------|----------------------|
| **tfsec**      | 53  | 9 Critical, 25 High, 11 Medium, 8 Low | Public S3 buckets, open security groups (`0.0.0.0/0`), unencrypted RDS and DynamoDB instances, weak IAM policies |
| **Checkov**    | 78  |  - | Hardcoded AWS keys, no encryption or backups for RDS, IAM wildcard permissions, S3 versioning/logging disabled, public access blocks off |
| **Terrascan**  | 22  | 14 High, 8 Medium | Unrestricted SG ports (22, 3306, 3389), public S3 buckets, lack of CloudWatch logs, missing IAM authentication |

**Analysis:**  
- **Checkov** produced the highest number of findings (78) due to its extensive AWS CIS and NIST policy library.  
- **tfsec** highlighted the most critical misconfigurations like public access and encryption issues in RDS/S3.  
- **Terrascan** effectively detected network exposure, database access risk, and IAM misconfigurations.  
These tools complement each other — using them together ensures full coverage of code- and policy-level Terraform misconfigurations.

---

### 1.2 Pulumi Security Analysis — KICS

KICS scanned the Pulumi YAML manifests and identified misconfigurations and secrets exposure.

| Severity | Count | Examples |
|-----------|--------|----------|
| **CRITICAL** | 0 | — |
| **HIGH** | 2 | Hardcoded password/secret, unencrypted DynamoDB table |
| **MEDIUM** | 2 | RDS publicly accessible, EC2 monitoring disabled |
| **LOW** | 0 | — |
| **INFO** | 2 | EBS not optimized, DynamoDB recovery disabled |
| **Total** | **6 Findings** |  |

**Examples of findings:**
- Hardcoded credentials found in environment configuration.  
- DynamoDB table lacked encryption.  
- RDS instance marked publicly accessible.  
- EC2 instance missing monitoring.

**Observation:**  
KICS successfully parsed Pulumi YAML and detected cloud resource misconfigurations and secrets. It provides a Pulumi-specific rule set for AWS, Azure, and GCP, confirming strong Pulumi support.

---

### 1.3 Terraform vs Pulumi Comparison

| Aspect | Terraform (tfsec, Checkov, Terrascan) | Pulumi (KICS) |
|--------|--------------------------------------|---------------|
| Format | Declarative (HCL) | Programmatic (YAML) |
| Findings Count | 53–78 | 6 |
| Common Risks | IAM over-permissiveness, S3 encryption gaps, network exposure | Secrets in code, missing encryption and monitoring |
| Best Tool | Checkov for compliance breadth | KICS for Pulumi support |
| Focus | Infrastructure resource misconfigurations | Code-level configuration errors |

**Key Insight:**  
Terraform tools focus on network and compliance issues in static resources, while KICS identifies application-level IaC risks like embedded credentials and poor encryption defaults.

---

### 1.4 Critical Findings (5 Highlights)

1. Public S3 buckets without encryption (tfsec, Checkov).  
2. IAM roles with wildcard access privileges (Checkov).  
3. Open security groups allowing full ingress/egress to the internet (Terrascan, tfsec).  
4. Hardcoded passwords and secrets in Pulumi YAML (KICS).  
5. DynamoDB tables without encryption or recovery enabled (tfsec, KICS).

---

### 1.5 Tool Strengths

- **tfsec** – Lightweight static analysis with clear actionable remediation tips; great for early CI/CD validation.  
- **Checkov** – Most comprehensive compliance scanning, excellent for cloud governance.  
- **Terrascan** – Focused network and access validation with contextual policy grouping.  
- **KICS** – Best suited for Pulumi and multi-IaC environments; detects secrets and structural misconfigurations.

---

### 1.6 Recommendations

- Automate **tfsec**, **Checkov**, and **Terrascan** scans for Terraform during CI/CD to prevent insecure merges.  
- Include **KICS** in pipeline checks for Pulumi or Ansible-based deployments.  
- Integrate all reports into centralized dashboards (e.g., Jenkins, GitHub Actions, or GitLab CI) to track and visualize IaC security posture.  
- Prioritize remediation for encryption, IAM privilege, and network exposure misconfigurations.  

**Summary:**  
Your scans revealed a total of over **150 Terraform** and **6 Pulumi** issues.  
Terraform-based IaC showed high risk due to public access and encryption gaps, while Pulumi scans emphasized secret management problems.


## Task 2 — Ansible Security Scanning with KICS

### 2.1 KICS Ansible Scan Summary

KICS automatically detected and analyzed the vulnerable Ansible playbooks, highlighting configuration mistakes, weak security settings, and missing best practices.

| Severity | Count | Examples |
|-----------|--------|----------|
| **HIGH** | 3 | Hardcoded credentials in playbook variables, use of `shell` module with unescaped input, unencrypted SSH configuration |
| **MEDIUM** | 5 | Missing privilege escalation limits (`become: yes` used without restrictions), package installation without version pinning, insecure file permissions |
| **LOW** | 2 | Use of plaintext passwords for MySQL role, absence of handler notifications |
| **Total** | **10 Findings** |  |

---

### 2.2 Ansible Security Issues

- **Hardcoded Credentials**: Sensitive values for SSH and application passwords appear directly in Ansible YAML files. This introduces high risk of credential leakage.
- **Unrestricted Shell Commands**: Tasks use the `shell:` module to execute unsanitized user input, enabling potential command injection.
- **Unpinned Software Versions**: Using `apt` or `yum` modules without specifying versions can lead to unstable or unsafe system configurations.

---

### 2.3 Best Practice Violations

1. **“Hardcoded Sensitive Variables”** — All credentials should be stored using Ansible Vault or environment variables instead of plain text.  
   *Impact*: Increased risk of key leaks in version control.
2. **“Using shell Commands Without Sanitation”** — Replace `shell` or `command` executions with built-in Ansible modules (e.g., `copy`, `lineinfile`).  
   *Impact*: Possibility of arbitrary code execution on managed hosts.
3. **“Lack of Privilege Escalation Control”** — Using `become: yes` globally violates least privilege principle.  
   *Impact*: Allows unintended root-level operations.

---

### 2.4 KICS Ansible Queries

KICS applies over 120+ Ansible-specific queries to assess:
- Secret management — detection of hardcoded credentials and plaintext passwords.
- Command execution — validation of proper module use instead of raw shells.
- Security hardening — checks for secure permissions, user/group restrictions, and privilege enforcement.
- Compliance — identifies missing encryption, logging, or secure SSH configuration.

**Examples of KICS Query Categories:**
- "Secrets in Cleartext Variables"
- "Improper Use of become Privileges"
- "Insecure File or Directory Mode"

---

### 2.5 Remediation Steps

- Use **Ansible Vault** for sensitive keys and passwords.  
- Replace `shell:` or `command:` with idempotent modules like `file`, `service`, and `package`.  
- Enforce privilege escalation per task, not globally.  
- Limit `0777` permissions and replace with secure modes (`0640`, `0750`).  
- Define explicit package versions to ensure predictable, secure deployments.

---

### Summary

KICS found **10 total Ansible security issues** (3 high, 5 medium, 2 low) across the playbooks.  
Most critical issues involved **hardcoded credentials** and **improper privilege handling**.  
Addressing these significantly improves configuration compliance and security hygiene.


## Task 3 — Comparative Tool Analysis & Security Insights

### 3.1 Tool Comparison Summary

Based on your scan results:

| Criterion           | tfsec | Checkov | Terrascan | KICS (Pulumi + Ansible) |
|---------------------|-------|---------|-----------|-------------------------|
| Total Findings      | 53    | 78      | 22        | 15 (6 Pulumi + 9 Ansible) |
| Scan Speed          | Fast  | Medium  | Medium    | Medium                  |
| False Positives     | Medium| Medium  | Low       | Low                     |
| Report Quality     | ⭐⭐⭐⭐  | ⭐⭐⭐⭐⭐  | ⭐⭐⭐      | ⭐⭐⭐⭐                   |
| Ease of Use         | ⭐⭐⭐⭐  | ⭐⭐⭐     | ⭐⭐       | ⭐⭐⭐⭐                   |
| Documentation       | ⭐⭐⭐⭐  | ⭐⭐⭐⭐⭐  | ⭐⭐⭐      | ⭐⭐⭐                    |
| Platform Support    | Terraform only | Terraform + Cloud | Terraform + Cloud | Pulumi + Ansible + Multi-IaC |
| Output Formats      | JSON, Text, SARIF | JSON, Text, SARIF | JSON, Text | JSON, HTML, Text         |
| CI/CD Integration   | Easy  | Easy    | Medium    | Medium                  |
| Unique Strengths    | Quick analysis | Extensive compliance checks | Network & IAM focus | Multi-IaC & secret detection |

---

### 3.2 Vulnerability Category Analysis

| Security Category       | tfsec | Checkov | Terrascan | KICS (Pulumi) | KICS (Ansible) | Best Tool          |
|-------------------------|-------|---------|-----------|---------------|----------------|--------------------|
| Encryption Issues       | High  | High    | Medium    | High          | N/A            | Checkov/KICS Pulumi |
| Network Security        | High  | High    | High      | Medium        | Low            | Terrascan           |
| Secrets Management      | Low   | Medium  | Low       | High          | High           | KICS                |
| IAM/Permissions         | High  | High    | High      | Medium        | Medium         | Checkov             |
| Access Control          | Medium| High    | Medium    | Medium        | Medium         | Checkov             |
| Compliance/Best Practices | Medium| High    | Medium    | Medium        | Low            | Checkov             |

---

### 3.3 Top 5 Critical Findings

1. Public S3 buckets without encryption (tfsec, Checkov).  
2. IAM roles with wildcard access (Checkov).  
3. Open security groups exposing database ports (Terrascan).  
4. Hardcoded passwords in Pulumi and Ansible (KICS).  
5. Unencrypted DynamoDB tables and missing logging (tfsec, KICS).

---

### 3.4 Tool Selection Guide

- Use **tfsec** for rapid Terraform static analysis early in DevSecOps pipelines.  
- Choose **Checkov** for comprehensive compliance and security governance, especially for AWS environments.  
- Use **Terrascan** to detect detailed network and IAM misconfigurations during deployment validation.  
- Employ **KICS** to scan Pulumi and Ansible playbooks with broad multi-IaC support and secret detection.

---

### 3.5 Lessons Learned

- Combining multiple tools covers a wider range of issues than any single scanner.  
- Compliance-focused tools like Checkov detect issues missed by lightweight scanners like tfsec.  
- Secret detection remains a challenge best handled by KICS in multi-IaC pipelines.  
- False positives vary; tuning critical in CI/CD automation.

---

### 3.6 CI/CD Integration Strategy

- Integrate tfsec and Checkov in pull request checks for immediate feedback on Terraform code.  
- Run Terrascan before production deployment to verify network and IAM policies.  
- Use KICS for scanning Pulumi and Ansible playbooks as part of pre-deployment validation.  
- Aggregate findings into dashboards for unified security governance.

---

### 3.7 Justification

This multi-tool approach balances speed, coverage, and depth, matching real-world DevSecOps needs for secure, automated infrastructure deployments.
