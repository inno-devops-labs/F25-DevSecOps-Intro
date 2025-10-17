# Lab 6 — Infrastructure-as-Code Security: Scanning & Policy Enforcement (Submission)

## Task 1 — Terraform & Pulumi Security Scanning (evidence & findings)

| Aspect | tfsec | Checkov | Terrascan | Observations / Effectiveness |
| --- | --- | --- | --- | --- |
| Total findings | 53 | 78 | 22 | Checkov detects the largest set, tfsec fewer but very accurate, Terrascan focused on AWS best-practices |
| Accuracy (false positives) | Low | Medium | Medium | tfsec’s rule set is Terraform-specific and less noisy; Checkov’s broad coverage adds more false positives |
| Rule coverage | Terraform only (resource-level) | Multi-framework | Terraform, CloudFormation, K8s | Checkov > Terrascan > tfsec |
| Compliance mapping | None | CIS AWS, NIST, SOC2 | CIS AWS, PCI, OPA rules | Checkov and Terrascan strong for enterprise reporting |
| Unique strength | Developer-oriented static rules | Policy-as-code | OPA/Rego rules, compliance gating | tfsec best for developers, Checkov best for enterprise gates |

**Scan summary:**

- Files scanned: 1
- Total findings: 6 (2 HIGH / 2 MEDIUM / 2 INFO)

**Key findings from Pulumi KICS scan:**

| Severity | Finding | Description |
| --- | --- | --- |
| HIGH | DynamoDB Table Not Encrypted | Missing serverSideEncryption |
| HIGH | Passwords And Secrets – Generic | Hard-coded secret in YAML |
| MEDIUM | EC2 Monitoring Disabled | No monitoring attribute |
| MEDIUM | RDS Publicly Accessible | `publiclyAccessible: true` |
| INFO | DynamoDB PITR Disabled | `pointInTimeRecovery.enabled=false` |
| INFO | EC2 Not EBS Optimized | Missing `ebsOptimized` |

**Terraform vs Pulumi — Declarative HCL vs Programmatic YAML**

1. **Definition style:**
   - **Terraform (HCL):** declarative — static graph
   - **Pulumi (YAML / Code):** programmatic — imperative logic
   - **Security impact:** programmatic IaC adds flexibility but increases scanning complexity

2. **Scan coverage:**
   - **Terraform (HCL):** mature ecosystem (tfsec, Checkov, Terrascan)
   - **Pulumi (YAML / Code):** newer, fewer tools (KICS, Trivy)
   - **Security impact:** Terraform scans deeper and broader

3. **Typical issues:**
   - **Terraform:** misconfigurations such as public security groups, unencrypted S3 buckets, IAM issues
   - **Pulumi:** secrets hardcoding, runtime configuration issues, missing attributes
   - **Security impact:** Pulumi risks more human logic errors or secrets hardcoding

4. **Static analyzability:**
   - **Terraform (HCL):** easy — HCL is static
   - **Pulumi (YAML / Code):** harder — code constructs require parsing
   - **Security impact:** tools must interpret YAML/TS/Python outputs for Pulumi

5. **Example:**
   - **Terraform:** `storage_encrypted=false`
   - **Pulumi:** missing `serverSideEncryption` block
   - **Security impact:** same weakness, different expression

**KICS Pulumi Support — Query Catalog Evaluation**

1. **Encryption:**
   - **Example query:** DynamoDB Table Not Encrypted
   - **CWE:** 311
   - **Strength:** identifies missing SSE config

2. **Secret Management:**
   - **Example query:** Generic Password / Secrets in code
   - **CWE:** 798
   - **Strength:** detects hardcoded credentials

3. **Insecure Config:**
   - **Example query:** RDS Publicly Accessible
   - **CWE:** 284
   - **Strength:** matches Pulumi properties

4. **Observability:**
   - **Example query:** EC2 Monitoring Disabled
   - **CWE:** 778
   - **Strength:** ensures detailed monitoring

5. **Best Practices:**
   - **Example query:** EC2 Not EBS Optimized / PITR Disabled
   - **CWE:** 459
   - **Strength:** encourages resilience

---

**Critical Findings:**

| # | Issue | Severity | Detected By | Affected IaC |
| --- | --- | --- | --- | --- |
| 1 | Public RDS Instance (publicly_accessible=true) | HIGH | Checkov, Terrascan, KICS | Terraform & Pulumi |
| 2 | Open Security Groups (0.0.0.0/0) | CRITICAL | tfsec, Terrascan, Checkov | Terraform |
| 3 | Unencrypted DynamoDB/RDS/S3 | HIGH | All tools | Terraform & Pulumi |
| 4 | Hardcoded Secrets | HIGH | KICS | Pulumi & Ansible |
| 5 | Over-Permissive IAM Policies (*) | HIGH | tfsec, Checkov, Terrascan | Terraform |

**Tool Strengths Summary:**

| Tool | Excels At | Weakness |
| --- | --- | --- |
| tfsec | Terraform precision, developer speed | Terraform-only |
| Checkov | Compliance & multi-framework | Some noise / false positives |
| Terrascan | OPA rules + AWS compliance | Less breadth than Checkov |
| KICS | Pulumi/Ansible support + secret detection | Limited Pulumi coverage, pattern-based |

## Task 2 — Ansible Security Scanning (KICS) — findings & remediation

**Scanning results everity breakdown:**
- HIGH: 8
- LOW: 1
- MEDIUM: 0
- CRITICAL: 0

**Key security problems identified by KICS:**

| Problem | Files Affected | Type | Severity | Why It’s a Concern |
| --- | --- | --- | --- | --- |
| Hardcoded secrets and passwords | inventory.ini, configure.yml, deploy.yml | Generic passwords and password-in-URL patterns flagged by KICS | HIGH | Secrets in plaintext can lead to credential theft if the source is exposed (e.g., repo leak, backup, insider threat). They are often long-lived and can be reused by attackers to access systems, cloud APIs, or databases |
| Passwords embedded in URLs | deploy.yml | Credentials appearing within connection URLs or remote endpoints | HIGH | URLs are often logged, stored in CI variables, or shown in error messages, making passwords easily discoverable |
| Unpinned package installs (Ansible apt with latest) | deploy.yml | Supply-chain / stability risk | LOW | Installing the latest version can pull in unexpectedly updated packages (malicious or broken), introducing supply-chain risk and causing unpredictable behaviour |
| Multiple redundant hardcoded credentials across inventory and playbooks | Inventory and playbooks | Duplication of credentials | HIGH | Duplication increases the «blast radius» — if one credential is leaked, it can expose multiple hosts or services |
| Low-severity findings (e.g., unpinned package version) | — | Maintainability and stability risks | LOW | While lower severity, these issues can become security problems during upgrades or rollback events, affecting maintainability and stability |

The majority of detected issues are high severity and related to hardcoded secrets and credentials in the source

**Best Practice Violations:**

| Violation | What | Impact |
| --- | --- | --- |
| Hardcoded Secrets in Repo | Plaintext passwords or API keys inside Ansible inventory and playbooks | Immediate credential exposure if the repository is public or compromised; enables lateral movement and service takeover |
| Credentials in URLs | Username/password embedded in HTTP/DB/SSH URLs (e.g., https://user:pass@host/...) | Credentials may appear in logs, process lists, CI traces, or monitoring; accidental leak is common |
| Using latest for package installation | A task installs packages with state: latest or equivalent | Unexpected package upgrades can introduce vulnerabilities, break stability, or pull in malicious packages if upstream is compromised. It's a supply-chain risk |

**Evaluation of checks KICS performs**

| Category | Description | Strength | Limitation |
| --- | --- | --- | --- |
| Secret Management (high impact) | Generic password detection, password in URL detection, secret-like pattern matching | Catches many obvious secrets in different file formats (YAML, INI, templates) | May produce false positives (e.g., tokens or IDs that look like secrets) and may miss secrets generated at runtime |
| Supply-chain / Package Safety | Detects `apt/yum` usage with `state: latest` or missing version pins | Highlights unstable installation practices | Not all package managers or flows are exhaustively covered |
| Best Practices & Observability | Detects missing monitoring flags and other operational deficiencies (in other IaC contexts). For Ansible, it can point out practices that reduce maintainability and increase risk | Helps identify practices that can improve maintainability and reduce risk | — |
| Generic IaC Misconfiguration | Many queries are platform-agnostic (e.g., insecure values, default credentials, permissive ACLs). They are adapted to Ansible task signatures | Identifies common misconfigurations applicable across different platforms | — |

**Remediation Steps:**

1. Remove secrets from source control immediately:

2. Rotate any secrets that were committed

3. Use Ansible Vault for any sensitive variables

4. Use external secret managers

5. Integrate secrets into CI/CD

6. Add pre-commit hooks

## Task 3 — Comparative Tool Analysis & Security Insights

### 3.1 Tool Comparison Matrix

| Criterion | tfsec | Checkov | Terrascan | KICS |
| --- | --- | --- | --- | --- |
| **Total findings**| 53 | 78 | 22 | Pulumi: 6 / Ansible: 9 |
| **Primary focus** | Checks specific to Terraform | Supports multiple IaC tools and includes compliance checks | Focuses on compliance using OPA rules and is AWS-oriented | Supports Pulumi and Ansible, detects secrets, works with multiple IaC tools |
| **Scan speed** | Fast | Medium | Medium | Fast |
| **False positives** | Low number of false positives | Moderate number of false positives due to some verbose rules | Moderate number of false positives | Moderate number of false positives, pattern-based detection |
| **Report quality** | Concise reports | Verbose reports, well-suited for CI | Concise reports with compliance mapping | Good reports, supports JSON and HTML formats |
| **Platform support** | Only Terraform | Terraform, CloudFormation, K8s, Docker | Terraform, CloudFormation, K8s | Pulumi, Ansible, Terraform, K8s |
| **CI/CD integration** | Easy to integrate | Easy integration with rich options | Easy to integrate | Easy to integrate |
| **Unique strengths** | Detailed checks at the resource level for Terraform | Includes compliance frameworks like CIS and NIST, supports policy-as-code | Uses OPA/Rego policies, has rules specific to AWS | Supports Pulumi and Ansible manifests, includes secret detection |

### 3.2 Vulnerability Category Comparison

| Category | tfsec | Checkov | Terrascan | KICS (Pulumi) | KICS (Ansible) | Best tool |
| --- | --- | --- | --- | --- | --- | --- |
| Network (SG open, 0.0.0.0/0) | Yes (detailed) | Yes | Yes (port-level) | Yes (if in manifest) | N/A | tfsec / Terrascan |
| Encryption (RDS/DynamoDB/S3) | Yes | Yes | Yes | Yes | N/A | Terrascan / Checkov |
| IAM & privilege | Yes | Yes | Yes | Partial | Partial | Checkov / tfsec |
| Secrets in code | No | No | No | Yes (Pulumi YAML) | Yes (Ansible) | KICS |
| Backup/Resilience | Yes | Yes | Yes | Yes | Yes | Terrascan / Checkov |
| Compliance benchmarks (CIS/NIST) | No | Yes | Yes | Partial | Partial | Checkov / Terrascan |

---

**Top 5 Critical Findings (detailed, with remediation examples)**

1. **Publicly accessible RDS / DB instances (`publicly_accessible = true`)**

   **Why critical:** exposes DB endpoints to the internet; trivial for attackers to probe.

   **Detected by:** Checkov, Terrascan, KICS (Pulumi).

   **Remediation:**

   - **Terraform:**
     ```terraform
      publicly_accessible  = false
     ```

   - **Pulumi (YAML):**
     ```yaml
      publiclyAccessible: false
     ```

   - **Ansible:** ensure DB provisioning modules set `publicly_accessible: false` or configure the cloud provider console to block public access.

2. **Open Security Groups (Ingress/Egress `0.0.0.0/0`)**

   **Why critical:** allows any IP to connect; massive attack surface.

   **Detected by:** tfsec, Terrascan, Checkov.

   **Remediation (Terraform example):**
   ```terraform
    cidr_blocks = ["10.0.1.0/24"]  # <--- restrict
   ```

   **Best practice:** use least-privilege network rules, security group references instead of wide CIDRs

3. **Unencrypted resources at rest (`RDS storage_encrypted=false`, DynamoDB missing `serverSideEncryption`)**

   **Why high:** data exposure if snapshots or volumes are compromised.

   **Detected by:** tfsec, Terrascan, KICS.

   **Remediation:**

   - **Terraform (RDS and DynamoDB):**
     ```terraform
      storage_encrypted = true  # <--- fix
     ```

   - **Pulumi (YAML, DynamoDB):**
     ```yaml
      serverSideEncryption:
        enabled: true
     ```

4. **Hardcoded secrets in source (API keys, DB passwords)**

   **Why critical:** secrets in repositories lead to immediate compromise; easy to search and exfiltrate.

   **Detected by:** KICS (Pulumi/Ansible).

   **Remediation:**

   - **Ansible (use Ansible Vault):**
     ```yaml
     vars_files:
       - vars/secrets.yml
     # mark tasks with sensitive output as no_log: true
     ```

   - **Pulumi:**
     Use Pulumi Secrets Provider or cloud secrets manager:
     ```yaml
     config:
       myproject:dbPassword: ${pulumi:secrets}  # use Pulumi's secret system or set via env
     ```

   - **Terraform:**
     Move secrets to remote state or use variables from secret stores (e.g., AWS SSM, Secrets Manager) and do not hardcode.

5. **Overly permissive IAM policies (`"Action": ["*"]` or `"Resource":"*"`)**

   **Why high:** grants more privileges than required; enables privilege escalation.

   **Detected by:** tfsec, Checkov, Terrascan.

   **Remediation (Terraform example):**
   ```terraform
   resource "aws_iam_policy" "s3_read_only" {
     name   = "s3_read_only"
     policy = data.aws_iam_policy_document.s3_read_only.json
   }
   ```

   **Policy advice:** apply least privilege; use IAM roles for services; require review and approval for any policy that expands scope.

**Tool Strengths — what each tool excels at detecting**

**tfsec:**
* provides highly accurate checks specifically for Terraform code;
* offers clear, developer-friendly results with exact file and line references, minimizing false positives;
* well-suited for quick checks during the development process, such as in pre-commit hooks or PR reviews

**Checkov:**
* stands out for its compliance checking capabilities and policy-as-code approach;
* boasts a wide range of built-in checks and supports multiple IaC tools;
* ideal for integrating into CI/CD pipelines and meeting regulatory compliance requirements.

**Terrascan:**
* utilizes OPA/Rego rules and has extensive coverage of AWS-specific issues;
* effectively maps to compliance frameworks, making it suitable for establishing enterprise security baselines

**KICS:**
* natively supports Pulumi YAML and Ansible, with a particular focus on detecting secrets;
* delivers fast scanning performance, easy CI integration, and comprehensive support for multiple IaC languages

**Tool Selection Guide & Recommendations. CI/CD plan:**

Developer pre-commit & PR checks (fast feedback): tfsec + KICS (for Pulumi/Ansible)

Enterprise policy & compliance gate: Checkov (benchmarks) + Terrascan (OPA mapping)

Secret scanning: KICS

Comprehensive pipeline: Run tfsec on PR, then Checkov/Terrascan/KICS in CI for PRs

**Lessons learned and limitations:**

1. Specialized scanning is needed to detect secrets in the code. Standard Terraform scanners might not identify secrets that are embedded in other types of filesz

2. There is no universal tool that can detect all issues. It is recommended to use a combination of tools: developer tools (which provide fast analysis and few false positives) and CI tools (which focus on compliance and more thorough checks)

3. Some compliance checks can result in false positives. To address this, it is necessary to adjust the rules and implement a process for suppressing false positives and justifying them

4. Static analysis becomes more challenging with dynamic IaC (such as Pulumi). While scanning Pulumi YAML manifests is helpful, checking the code may require runtime analysis or abstract syntax tree (AST) analysis
