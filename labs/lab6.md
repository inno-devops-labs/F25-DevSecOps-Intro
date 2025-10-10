# Lab 6 — Infrastructure-as-Code Security: Scanning & Policy Enforcement

![difficulty](https://img.shields.io/badge/difficulty-intermediate-orange)
![topic](https://img.shields.io/badge/topic-IaC%20Security-blue)
![points](https://img.shields.io/badge/points-10-orange)

> **Goal:** Perform security analysis on vulnerable Infrastructure-as-Code using multiple scanning tools (tfsec, Checkov, Terrascan for Terraform; KICS for Pulumi and Ansible) and conduct comparative analysis to identify misconfigurations and security issues.  
> **Deliverable:** A PR from `feature/lab6` to the course repo with `labs/submission6.md` containing IaC security findings, tool comparison analysis, and security insights. Submit the PR link via Moodle.

---

## Overview

In this lab you will practice:
- Scanning **Terraform** infrastructure code with multiple security tools (tfsec, Checkov, Terrascan)
- Analyzing **Pulumi** infrastructure code with **KICS (Checkmarx)**, an open-source scanner with first-class Pulumi YAML support
- Scanning **Ansible** playbooks with **KICS** for security issues and misconfigurations
- Comparing different IaC security scanners to evaluate their effectiveness
- Analyzing critical security vulnerabilities and developing remediation strategies
- Recommending tool selection strategies for real-world DevSecOps pipelines

These skills are essential for shift-left security in infrastructure deployment and DevSecOps automation.

> You will work with intentionally vulnerable Terraform, Pulumi, and Ansible code provided in the course repository to practice identifying and fixing security misconfigurations.

---

## Tasks

### Task 1 — Terraform & Pulumi Security Scanning (5 pts)

**Objective:** Scan vulnerable Terraform and Pulumi configurations using multiple security tools to compare effectiveness and identify infrastructure security issues.

#### 1.1: Setup Scanning Environment

1. **Prepare Analysis Directory:**

   ```bash
   # Create analysis directory for all scan results
   mkdir -p labs/lab6/analysis
   ```

<details>
<summary>Vulnerable IaC Code Structure</summary>

**Location:** `labs/lab6/vulnerable-iac/`

**Terraform code** (`labs/lab6/vulnerable-iac/terraform/`):
- `main.tf` - AWS infrastructure with public S3 buckets, hardcoded credentials
- `security_groups.tf` - Overly permissive security rules (0.0.0.0/0)
- `database.tf` - Unencrypted RDS instances, public databases
- `iam.tf` - Wildcard IAM permissions, privilege escalation
- `variables.tf` - Insecure default values, hardcoded secrets

**Pulumi code** (`labs/lab6/vulnerable-iac/pulumi/`):
- `__main__.py` - Python-based infrastructure with 21 security issues
- `Pulumi.yaml` - Configuration with default secret values
- `Pulumi-vulnerable.yaml` - YAML-based Pulumi manifest (for KICS scanning)
- Includes: public S3, open security groups, unencrypted databases

**Ansible code** (`labs/lab6/vulnerable-iac/ansible/`):
- `deploy.yml` - Hardcoded secrets, poor command execution
- `configure.yml` - Weak SSH config, security misconfigurations
- `inventory.ini` - Credentials in plaintext

**Total: 80+ intentional security vulnerabilities across all frameworks**

> **Note:** Pulumi code includes both Python and YAML formats. KICS is used for Pulumi scanning due to its first-class support for Pulumi YAML manifests and comprehensive query catalog.

</details>

#### 1.2: Scan with tfsec

1. **Run tfsec Security Scanner:**

   ```bash
   # Scan Terraform code with tfsec (JSON output)
   docker run --rm -v "$(pwd)/labs/lab6/vulnerable-iac/terraform":/src \
     aquasec/tfsec:latest /src \
     --format json > labs/lab6/analysis/tfsec-results.json

   # Generate readable report
   docker run --rm -v "$(pwd)/labs/lab6/vulnerable-iac/terraform":/src \
     aquasec/tfsec:latest /src > labs/lab6/analysis/tfsec-report.txt
   ```

#### 1.3: Scan with Checkov

1. **Run Checkov Security Scanner:**

   ```bash
   # Scan with Checkov (JSON output)
   docker run --rm -v "$(pwd)/labs/lab6/vulnerable-iac/terraform":/tf \
     bridgecrew/checkov:latest \
     -d /tf --framework terraform \
     -o json > labs/lab6/analysis/checkov-terraform-results.json

   # Generate readable report
   docker run --rm -v "$(pwd)/labs/lab6/vulnerable-iac/terraform":/tf \
     bridgecrew/checkov:latest \
     -d /tf --framework terraform \
     --compact > labs/lab6/analysis/checkov-terraform-report.txt
   ```

#### 1.4: Scan with Terrascan

1. **Run Terrascan Security Scanner:**

   ```bash
   # Scan with Terrascan (JSON output)
   docker run --rm -v "$(pwd)/labs/lab6/vulnerable-iac/terraform":/iac \
     tenable/terrascan:latest scan \
     -i terraform -d /iac \
     -o json > labs/lab6/analysis/terrascan-results.json

   # Generate readable report
   docker run --rm -v "$(pwd)/labs/lab6/vulnerable-iac/terraform":/iac \
     tenable/terrascan:latest scan \
     -i terraform -d /iac \
     -o human > labs/lab6/analysis/terrascan-report.txt
   ```

#### 1.5: Terraform Scanning Analysis

1. **Compare Tool Results:**

   ```bash
   echo "=== Terraform Security Analysis ===" > labs/lab6/analysis/terraform-comparison.txt
   
   # Count findings from each tool
   tfsec_count=$(jq '.results | length' labs/lab6/analysis/tfsec-results.json 2>/dev/null || echo "0")
   checkov_count=$(jq '.summary.failed' labs/lab6/analysis/checkov-terraform-results.json 2>/dev/null || echo "0")
   terrascan_count=$(jq '.results.scan_summary.violated_policies' labs/lab6/analysis/terrascan-results.json 2>/dev/null || echo "0")
   
   echo "tfsec findings: $tfsec_count" >> labs/lab6/analysis/terraform-comparison.txt
   echo "Checkov findings: $checkov_count" >> labs/lab6/analysis/terraform-comparison.txt
   echo "Terrascan findings: $terrascan_count" >> labs/lab6/analysis/terraform-comparison.txt
   ```

#### 1.6: Scan Pulumi Code with KICS

1. **Scan Pulumi with KICS (Checkmarx):**

   KICS provides first-class Pulumi support and scans Pulumi YAML manifests directly. It includes a comprehensive catalog of Pulumi-specific security queries for AWS, Azure, GCP, and Kubernetes resources.

   ```bash
   # Scan Pulumi with KICS (JSON and HTML reports)
   docker run -t --rm -v "$(pwd)/labs/lab6/vulnerable-iac/pulumi":/src \
     checkmarx/kics:latest \
     scan -p /src -o /src/kics-report --report-formats json,html

   # Move reports to analysis directory
   sudo mv labs/lab6/vulnerable-iac/pulumi/kics-report/results.json labs/lab6/analysis/kics-pulumi-results.json
   sudo mv labs/lab6/vulnerable-iac/pulumi/kics-report/results.html labs/lab6/analysis/kics-pulumi-report.html

   # Generate readable summary (console output)
   docker run -t --rm -v "$(pwd)/labs/lab6/vulnerable-iac/pulumi":/src \
     checkmarx/kics:latest \
     scan -p /src --minimal-ui > labs/lab6/analysis/kics-pulumi-report.txt 2>&1 || true
   ```

2. **Analyze Pulumi Results:**

   ```bash
   echo "=== Pulumi Security Analysis (KICS) ===" > labs/lab6/analysis/pulumi-analysis.txt
   
   # KICS JSON structure: queries_total, queries_failed (vulnerabilities found)
   high_severity=$(jq '.severity_counters.HIGH // 0' labs/lab6/analysis/kics-pulumi-results.json 2>/dev/null || echo "0")
   medium_severity=$(jq '.severity_counters.MEDIUM // 0' labs/lab6/analysis/kics-pulumi-results.json 2>/dev/null || echo "0")
   low_severity=$(jq '.severity_counters.LOW // 0' labs/lab6/analysis/kics-pulumi-results.json 2>/dev/null || echo "0")
   total_findings=$(jq '.total_counter // 0' labs/lab6/analysis/kics-pulumi-results.json 2>/dev/null || echo "0")
   
   echo "KICS Pulumi findings: $total_findings" >> labs/lab6/analysis/pulumi-analysis.txt
   echo "  HIGH severity: $high_severity" >> labs/lab6/analysis/pulumi-analysis.txt
   echo "  MEDIUM severity: $medium_severity" >> labs/lab6/analysis/pulumi-analysis.txt
   echo "  LOW severity: $low_severity" >> labs/lab6/analysis/pulumi-analysis.txt
   ```

In `labs/submission6.md`, document:
- **Terraform Tool Comparison** - Effectiveness of tfsec vs. Checkov vs. Terrascan
- **Pulumi Security Analysis** - Findings from KICS on Pulumi code
- **Terraform vs. Pulumi** - Compare security issues between declarative HCL and programmatic YAML approaches
- **KICS Pulumi Support** - Evaluate KICS's Pulumi-specific query catalog
- **Critical Findings** - At least 5 significant security issues
- **Tool Strengths** - What each tool excels at detecting

---

### Task 2 — Ansible Security Scanning with KICS (2 pts)

**Objective:** Scan vulnerable Ansible playbooks using KICS to identify security issues, misconfigurations, and best practice violations.

#### 2.1: Scan Ansible Playbooks with KICS

<details>
<summary>Vulnerable Ansible Code Structure</summary>

The provided Ansible code includes common security issues:
- `deploy.yml` - Playbook with hardcoded secrets
- `configure.yml` - Tasks without `no_log` for sensitive operations
- `inventory.ini` - Insecure inventory configuration

KICS provides comprehensive Ansible security queries for:
- Secrets management issues
- Command execution vulnerabilities
- File permissions and access control
- Authentication and access issues
- Insecure configurations

</details>

1. **Run KICS Security Scanner for Ansible:**

   KICS auto-detects Ansible playbooks and applies Ansible-specific security queries:

   ```bash
   # Scan Ansible playbooks with KICS (JSON and HTML reports)
   docker run -t --rm -v "$(pwd)/labs/lab6/vulnerable-iac/ansible":/src \
     checkmarx/kics:latest \
     scan -p /src -o /src/kics-report --report-formats json,html

   # Move reports to analysis directory
   sudo mv labs/lab6/vulnerable-iac/ansible/kics-report/results.json labs/lab6/analysis/kics-ansible-results.json
   sudo mv labs/lab6/vulnerable-iac/ansible/kics-report/results.html labs/lab6/analysis/kics-ansible-report.html

   # Generate readable summary
   docker run -t --rm -v "$(pwd)/labs/lab6/vulnerable-iac/ansible":/src \
     checkmarx/kics:latest \
     scan -p /src --minimal-ui > labs/lab6/analysis/kics-ansible-report.txt 2>&1 || true
   ```

#### 2.2: Ansible Security Analysis

1. **Analyze KICS Ansible Results:**

   ```bash
   echo "=== Ansible Security Analysis (KICS) ===" > labs/lab6/analysis/ansible-analysis.txt
   
   # Count findings by severity
   high_severity=$(jq '.severity_counters.HIGH // 0' labs/lab6/analysis/kics-ansible-results.json 2>/dev/null || echo "0")
   medium_severity=$(jq '.severity_counters.MEDIUM // 0' labs/lab6/analysis/kics-ansible-results.json 2>/dev/null || echo "0")
   low_severity=$(jq '.severity_counters.LOW // 0' labs/lab6/analysis/kics-ansible-results.json 2>/dev/null || echo "0")
   total_findings=$(jq '.total_counter // 0' labs/lab6/analysis/kics-ansible-results.json 2>/dev/null || echo "0")
   
   echo "KICS Ansible findings: $total_findings" >> labs/lab6/analysis/ansible-analysis.txt
   echo "  HIGH severity: $high_severity" >> labs/lab6/analysis/ansible-analysis.txt
   echo "  MEDIUM severity: $medium_severity" >> labs/lab6/analysis/ansible-analysis.txt
   echo "  LOW severity: $low_severity" >> labs/lab6/analysis/ansible-analysis.txt
   ```

In `labs/submission6.md`, document:
- **Ansible Security Issues** - Key security problems identified by KICS
- **Best Practice Violations** - Explain at least 3 violations and their security impact
- **KICS Ansible Queries** - Evaluate the types of security checks KICS performs
- **Remediation Steps** - How to fix the identified issues

---

### Task 3 — Comparative Tool Analysis & Security Insights (3 pts)

**Objective:** Analyze and compare the effectiveness of different IaC security scanning tools to understand their strengths and weaknesses, and develop insights for tool selection in real-world scenarios.

#### 3.1: Create Comprehensive Tool Comparison

1. **Generate Summary Statistics:**

   ```bash
   # Generate comprehensive comparison statistics
   echo "=== Comprehensive Tool Comparison ===" > labs/lab6/analysis/tool-comparison.txt
   
   # Terraform tools
   tfsec_count=$(jq '.results | length' labs/lab6/analysis/tfsec-results.json 2>/dev/null || echo "0")
   checkov_tf_count=$(jq '.summary.failed' labs/lab6/analysis/checkov-terraform-results.json 2>/dev/null || echo "0")
   terrascan_count=$(jq '.results.scan_summary.violated_policies' labs/lab6/analysis/terrascan-results.json 2>/dev/null || echo "0")
   
   # Pulumi tool
   kics_pulumi_count=$(jq '.total_counter // 0' labs/lab6/analysis/kics-pulumi-results.json 2>/dev/null || echo "0")
   
   # Ansible tool
   kics_ansible_count=$(jq '.total_counter // 0' labs/lab6/analysis/kics-ansible-results.json 2>/dev/null || echo "0")
   
   echo "Terraform Scanning Results:" >> labs/lab6/analysis/tool-comparison.txt
   echo "  - tfsec: $tfsec_count findings" >> labs/lab6/analysis/tool-comparison.txt
   echo "  - Checkov: $checkov_tf_count findings" >> labs/lab6/analysis/tool-comparison.txt
   echo "  - Terrascan: $terrascan_count findings" >> labs/lab6/analysis/tool-comparison.txt
   echo "" >> labs/lab6/analysis/tool-comparison.txt
   echo "Pulumi Scanning Results (KICS): $kics_pulumi_count findings" >> labs/lab6/analysis/tool-comparison.txt
   echo "Ansible Scanning Results (KICS): $kics_ansible_count findings" >> labs/lab6/analysis/tool-comparison.txt
   ```

2. **Create Tool Effectiveness Matrix:**

   In `labs/submission6.md`, create a comprehensive comparison table:

   | Criterion | tfsec | Checkov | Terrascan | KICS |
   |-----------|-------|---------|-----------|------|
   | **Total Findings** | # | # | # | # (Pulumi + Ansible) |
   | **Scan Speed** | Fast/Medium/Slow | | | |
   | **False Positives** | Low/Med/High | | | |
   | **Report Quality** | ⭐-⭐⭐⭐⭐ | | | |
   | **Ease of Use** | ⭐-⭐⭐⭐⭐ | | | |
   | **Documentation** | ⭐-⭐⭐⭐⭐ | | | |
   | **Platform Support** | Terraform only | Multiple | Multiple | Multiple |
   | **Output Formats** | JSON, text, SARIF, etc | | | |
   | **CI/CD Integration** | Easy/Medium/Hard | | | |
   | **Unique Strengths** | | | | |

#### 3.2: Vulnerability Category Analysis

1. **Categorize Findings by Security Domain:**

   In `labs/submission6.md`, analyze tool performance across security categories:

   | Security Category | tfsec | Checkov | Terrascan | KICS (Pulumi) | KICS (Ansible) | Best Tool |
   |------------------|-------|---------|-----------|---------------|----------------|----------|
   | **Encryption Issues** | ? | ? | ? | ? | N/A | ? |
   | **Network Security** | ? | ? | ? | ? | ? | ? |
   | **Secrets Management** | ? | ? | ? | ? | ? | ? |
   | **IAM/Permissions** | ? | ? | ? | ? | ? | ? |
   | **Access Control** | ? | ? | ? | ? | ? | ? |
   | **Compliance/Best Practices** | ? | ? | ? | ? | ? | ? |

   **Instructions:**
   - Review the JSON/HTML reports from each tool
   - Count findings in each security category
   - Identify which tools excel at detecting specific issue types
   - Note unique findings detected by only one tool

In `labs/submission6.md`, document:
- **Tool Comparison Matrix** - Comprehensive evaluation with all metrics
- **Category Analysis** - Tool performance across security domains
- **Top 5 Critical Findings** - Detailed analysis with remediation code examples
- **Tool Selection Guide** - Recommendations for different use cases
- **Lessons Learned** - Insights about tool effectiveness, false positives, and limitations
- **CI/CD Integration Strategy** - Practical multi-stage pipeline recommendations
- **Justification** - Explain your reasoning for tool choices and strategy

---

## Acceptance Criteria

- ✅ Branch `feature/lab6` exists with commits for each task.
- ✅ File `labs/submission6.md` contains required analysis for Tasks 1-3.
- ✅ Terraform scanned with tfsec, Checkov, and Terrascan.
- ✅ Pulumi scanned with KICS (Checkmarx).
- ✅ Ansible playbooks scanned with KICS (Checkmarx).
- ✅ Comparative analysis completed with tool evaluation matrices.
- ✅ All scan results and analysis outputs committed.
- ✅ PR from `feature/lab6` → **course repo main branch** is open.
- ✅ PR link submitted via Moodle before the deadline.

---

## How to Submit

1. Create a branch for this lab and push it to your fork:

   ```bash
   git switch -c feature/lab6
   # create labs/submission6.md with your findings
   git add labs/submission6.md labs/lab6/analysis/
   git commit -m "docs: add lab6 submission - IaC security scanning and comparative analysis"
   git push -u origin feature/lab6
   ```

2. Open a PR from your fork's `feature/lab6` branch → **course repository's main branch**.

3. In the PR description, include:

   ```text
   - [x] Task 1 done — Terraform & Pulumi scanning with multiple tools
   - [x] Task 2 done — Ansible security analysis
   - [x] Task 3 done — Comparative tool analysis and security insights
   ```

4. **Copy the PR URL** and submit it via **Moodle before the deadline**.

---

## Rubric (10 pts)

| Criterion                                                        | Points |
| ---------------------------------------------------------------- | -----: |
| Task 1 — Terraform & Pulumi scanning (multiple tools) + analysis |  **5** |
| Task 2 — Ansible scanning (KICS) + remediation                  |  **2** |
| Task 3 — Comparative analysis + security insights               |  **3** |
| **Total**                                                        | **10** |

---

## Guidelines

- Use clear Markdown headers to organize sections in `submission6.md`.
- Include evidence from tool outputs (JSON excerpts, command outputs) to support your analysis.
- Focus on practical insights about tool selection for IaC security.
- Provide actionable remediation steps for identified issues.
- Document any challenges encountered with different tools.

<details>
<summary>Directory Structure After Lab</summary>

```
labs/lab6/
├── vulnerable-iac/          # Vulnerable code to scan (DO NOT MODIFY)
│   ├── terraform/           # 30 Terraform vulnerabilities
│   ├── pulumi/              # 21 Pulumi vulnerabilities
│   ├── ansible/             # 26 Ansible vulnerabilities
│   └── README.md            # Vulnerability catalog
├── analysis/                # All scan results and analysis
│   ├── tfsec-results.json
│   ├── tfsec-report.txt
│   ├── checkov-terraform-results.json
│   ├── checkov-terraform-report.txt
│   ├── terrascan-results.json
│   ├── terrascan-report.txt
│   ├── kics-pulumi-results.json
│   ├── kics-pulumi-report.html
│   ├── kics-pulumi-report.txt
│   ├── kics-ansible-results.json
│   ├── kics-ansible-report.html
│   ├── kics-ansible-report.txt
│   ├── tool-comparison.txt
│   ├── terraform-comparison.txt
│   ├── pulumi-analysis.txt
│   └── ansible-analysis.txt
└── submission6.md            # Your submission document
```

</details>

<details>
<summary>Common Issues & Troubleshooting</summary>

**Issue: Docker volume mount permission errors**
```bash
# Solution: Ensure you're running commands from the project root directory
pwd  # Should show path ending in the course repo name
```

**Issue: jq command not found**
```bash
# Install jq for JSON parsing
# macOS: brew install jq
# Ubuntu: sudo apt-get install jq
# Windows WSL: sudo apt-get install jq
```

**Issue: Checkov output format**
```bash
# Checkov uses -o flag for output format (json, cli, sarif, etc.)
# Use shell redirection (>) to save output to a specific file
# Example: -o json > output.json
```

**Issue: KICS exits with non-zero exit code**
```bash
# This is expected when vulnerabilities are found
# We use "|| true" to continue execution and capture the output
# Alternative: Use --ignore-on-exit results to suppress non-zero exit codes
```

**Issue: KICS not detecting Pulumi files**
```bash
# Ensure Pulumi-vulnerable.yaml is in the scan directory
# KICS auto-detects Pulumi YAML files by extension and content
# Verify KICS version supports Pulumi (v1.6.x+)
# Use: docker run --rm checkmarx/kics:latest version
```

**Issue: KICS report directory not found**
```bash
# KICS creates the report directory automatically
# Ensure you're using -o flag with proper path: -o /src/kics-report
# The container path must match the mounted volume
```

</details>

<details>
<summary>Tool Comparison Reference</summary>

**Terraform Scanning Tools:**
- **tfsec**: Fast, Terraform-specific scanner with low false positives
- **Checkov**: Policy-as-code approach with 1000+ built-in policies (supports Terraform, CloudFormation, K8s, Docker)
- **Terrascan**: OPA-based scanner with compliance framework mapping

**Pulumi Scanning:**
- **KICS (Checkmarx)**: Open-source scanner with first-class Pulumi YAML support
  - Dedicated Pulumi queries catalog for AWS, Azure, GCP, and Kubernetes
  - Auto-detects Pulumi platform
  - Announced Pulumi support in v1.6.x with continued expansion
  - Provides JSON, HTML, SARIF, and console output formats

**Ansible Scanning:**
- **KICS (Checkmarx)**: Open-source scanner with comprehensive Ansible security queries
  - Dedicated Ansible queries catalog
  - Detects secrets management issues, command injection, insecure configurations
  - Same tool across Terraform, Pulumi, and Ansible for consistency

**Tool Selection Guidelines:
- **tfsec**: Use for fast CI/CD scans, Terraform-specific checks
- **Checkov**: Use for comprehensive Terraform and multi-framework coverage (CloudFormation, K8s, Docker)
- **KICS**: Use for Pulumi and Ansible scanning with first-class support and extensive query catalog
  - Provides unified scanning across Pulumi and Ansible
  - Comprehensive security queries for AWS, Azure, GCP, Kubernetes resources
  - Single tool for consistency across multiple IaC frameworks
- **Terrascan**: Use for compliance-focused scanning (PCI-DSS, HIPAA, etc.)
- **Conftest**: Use for custom organizational policy enforcement across all IaC types

</details>

<details>
<summary>Common IaC Security Issues</summary>

**Common Terraform & Pulumi Issues:**
- Unencrypted S3 buckets and RDS instances
- Security groups allowing 0.0.0.0/0 access
- Hardcoded credentials and secrets
- Missing resource tags for governance
- Overly permissive IAM policies
- Publicly accessible databases

**Common Ansible Issues:**
- Hardcoded passwords in playbooks
- Missing `no_log` on sensitive tasks
- Overly permissive file permissions (0777)
- Using `shell` instead of proper modules
- Missing `become` privilege escalation controls
- Unencrypted Ansible Vault or missing vault usage

**Security Requirements to Enforce:**
- Encryption requirements (at-rest and in-transit)
- Network segmentation and access controls
- Tagging standards for governance and cost allocation
- Region restrictions and compliance requirements
- IAM least-privilege principles
- Regular security assessments and audits

</details>

<details>
<summary>Remediation Best Practices</summary>

**Terraform & Pulumi Remediation:**
- Enable S3 bucket encryption with `server_side_encryption_configuration`
- Restrict security group ingress to specific CIDR blocks
- Use AWS Secrets Manager or Parameter Store for credentials
- Add required tags to all resources
- Implement least-privilege IAM policies
- Set RDS instances to `storage_encrypted = true`

**Ansible Remediation:**
- Use Ansible Vault for all secrets: `ansible-vault encrypt vars.yml`
- Add `no_log: true` to tasks handling sensitive data
- Set proper file permissions (0644 for configs, 0600 for keys)
- Use Ansible modules instead of `shell`/`command` where possible
- Implement proper `become` with specific users
- Regular security updates in playbooks

**Security Scanning Best Practices:**
- Integrate security scanning into CI/CD pipelines
- Use pre-commit hooks for early detection
- Run multiple tools for comprehensive coverage
- Regularly update scanning tools and their rule sets
- Document and track remediation progress
- Establish SLAs for fixing critical/high severity issues

</details>
