### Terraform Tool Comparison

**1. Total issues found:**
* **tfsec:** 18 files detected.
* **Checkov:** 12 files detected.
* **Terrascan:** 22 files detected.

**2. Issues severity:**
* **tfsec:** 4 Critical, 2 High, 1 Medium, 3+ Low.
* **Checkov:** Severity missing.
* **Terrascan:** 14 High, 8 Medium.

**3. Scan scope:**
* **tfsec:** Terraform only.
* **Checkov:** Terraform, CloudFormation, Kubernetes, ARM, Helm.
* **Terrascan:** Terraform, Kubernetes, CloudFormation.

**4. Performance:**
* **tfsec:** Very fast, minimal dependencies.
* **Checkov:** Moderate.
* **Terrascan:** Slightly slower than tfsec but faster than Checkov.

**5. Detection quality:**
* **tfsec:** Detects specific egress/ingress rules with line precision, generally shows poor results.
* **Checkov:** Most compliance-ready, most detailed IAM security scanning.
* **Terrascan:** Most complete with the most comprehensive coverage, and most AWS-specific operational resilience.

### Pulumi Security Analysis — Key Findings

1. **DynamoDB Table Not Encrypted** (HIGH): `serverSideEncryption` missing — unencrypted data at rest.
2. **Passwords and Secrets in Code** (HIGH): Hardcoded secret key found in Pulumi YAML.
3. **EC2 Instance Monitoring Disabled** (MEDIUM): Missing `monitoring=true`, limits visibility.
4. **RDS Publicly Accessible** (MEDIUM): RDS instance allows public access.
5. **DynamoDB PITR Disabled** (INFO): `pointInTimeRecovery` disabled — reduced recoverability.
6. **EC2 Not EBS Optimized** (INFO): Missing `ebsOptimized=true`, potential performance issue.

### Terraform vs. Pulumi

**Terraform (HCL):**
* Offers stronger static security guarantees — safer defaults, predictable scanning, mature tooling (tfsec, Checkov, Terrascan).

**Pulumi (Programmatic IaC):**
* Offers developer agility, but increases security risk:
  * Dynamic code can bypass policy checks.
  * Secrets and credentials are often embedded in source.
  * Requires discipline and runtime scanning.

Terraform’s declarative HCL is easier to statically validate and harder to abuse programmatically. Pulumi’s flexibility increases developer productivity — but also increases potential attack surface via code execution and dynamic secrets.

### KICS Pulumi Support

1. **Baseline misconfiguration coverage:** Good — covers encryption, public exposure, best practices.
2. **Secret detection:** Strong — includes generic password queries.
3. **Provider / resource breadth:** Medium — common resources likely well supported; exotic ones less so.
4. **Dynamic logic / code support:** Weak — can’t analyze runtime-generated logic.
5. **Documentation & discoverability:** Weak — lack of dedicated Pulumi query docs.

KICS’s Pulumi support is functional and valuable for many common misconfigurations, but not (yet) a full replacement for deeper policy checks or runtime-aware security analysis in Pulumi.

### Critical Findings

1. **Publicly Accessible Databases (RDS / DB Instances)** [Checkov, Terrascan, KICS] — High: RDS instances have `publicly_accessible = true`.
2. **Unencrypted Data at Rest (RDS / DynamoDB)** [tfsec, Terrascan, KICS] — High: Missing `storage_encrypted` or `serverSideEncryption` attributes.
3. **Open Security Groups (0.0.0.0/0)** [tfsec, Terrascan] — Critical: Ingress/egress open to all IPs or ports.
4. **Hardcoded Secrets or Passwords in Source Code** [KICS] — Critical: Static secrets detected in Pulumi YAML.
5. **IAM Policy Wildcards** [tfsec, Terrascan, Checkov] — High: IAM permissions too broad — enables privilege escalation or resource deletion.

### Tool Strength

* **tfsec:** Terraform-native static analysis with high accuracy and low false positives. Detects granular misconfigurations at the resource level.
* **Checkov:** Broad compliance coverage — integrates CIS, NIST, GDPR, SOC2 policies. Great for multi-IaC and compliance enforcement.
* **Terrascan:** Comprehensive AWS detection. Covers ports, backups, IAM, encryption, and resilience. Uses OPA/Rego for extensibility.
* **KICS:** Secret detection + Pulumi YAML scanning. Works across IaC types including Pulumi, Docker, and Kubernetes. Provides fast scanning.

### Ansible Security Issues

1. Hardcoded secrets and passwords (files: inventory.ini, configure.yml, deploy.yml).
2. Passwords embedded in URLs (deploy.yml).
3. Unpinned package installs (Ansible apt with latest) (deploy.yml).
4. Multiple redundant hardcoded credentials across inventory and playbooks.
5. Unpinned package version — can become a security issue during upgrades or rollback events.

### Best Practice Violations — Explanation

1. **Hardcoded secrets and passwords:** Secrets in plaintext lead to credential theft if the source is exposed. They are often long-lived and can be reused by attackers to access systems.
2. **Passwords embedded in URLs:** URLs are often logged, stored in CI variables, or shown in error messages — making passwords trivially discoverable.
3. **Unpinned package installs:** Installing the latest can pull in unexpectedly updated packages (malicious or broken), introducing supply-chain risk.

### KICS Ansible Queries

KICS provides:
1. **Secret Management:** generic password detection, password in URL detection, secret-like pattern matching.
2. **Package Safety:** detects apt/yum usage with `state: latest` or missing version pins.
3. **Best Practices & Observability:** detects missing monitoring flags and other operational deficiencies (in other IaC contexts).

KICS provides a useful, broad set of pattern-based checks that quickly surface glaring issues.

### Remediation Steps

1. **Credentials in URLs:** remove credentials from URLs and instead use dedicated variables or secret lookups.
2. **Remove secrets from source control immediately:** search the repo and replace any plaintext secrets. Use external secret managers.
3. **Rotate any secrets that were committed:** assume compromise for secrets that were in repo history or backups.
4. **Package version pinning:** avoid `state: latest` in production playbooks. Pin packages to explicit versions when possible.

### Tool Effectiveness Matrix

| Criterion | tfsec | Checkov | Terrascan | KICS |
| --- | --- | --- | --- | --- |
| **Total findings** (this lab) | **53** | **78** | **22** | Pulumi: 6 / Ansible: 9 |
| **Primary focus** | Terraform-specific checks | Multi-IaC + compliance | OPA-based compliance + AWS-centric | Multi-IaC (Pulumi/Ansible), secret detection |
| **Scan speed** | Fast | Medium | Medium | Fast |
| **False positives** | Low | Medium (some verbose rules) | Medium | Medium (pattern-based) |
| **Report quality** | Concise | Verbose, CI-ready | Concise + compliance mapping | Good; supports JSON/HTML |
| **Platform support** | Terraform only | Terraform, CFN, K8s, Docker | Terraform, CFN, K8s | Pulumi, Ansible, Terraform, K8s |
| **CI/CD integration** | Easy | Easy (rich integrations) | Easy | Easy |
| **Unique strengths** | Precise resource-level Terraform checks | Compliance frameworks (CIS/NIST), policy-as-code | OPA/Rego policies and AWS-specific rules | Pulumi & Ansible manifest support; secrets detection |

### Vulnerability Category Analysis

| Category | tfsec | Checkov | Terrascan | KICS (Pulumi) | KICS (Ansible) | Best tool |
| --- | --- | --- | --- | --- | --- | --- |
| **Network (SG open, 0.0.0.0/0)** | Yes (detailed) | Yes | Yes (port-level) | Yes (if in manifest) | N/A | tfsec / Terrascan |
| **Encryption (RDS/DynamoDB/S3)** | Yes | Yes | Yes | Yes | N/A | Terrascan / Checkov |
| **IAM & privilege** | Yes | Yes | Yes | Partial | Partial | Checkov / tfsec |
| **Secrets in code** | No | No | No | Yes (Pulumi YAML) | Yes (Ansible) | KICS |
| **Backup/Resilience** | Yes | Yes | Yes | Yes | Yes | Terrascan / Checkov |
| **Compliance benchmarks (CIS/NIST)** | No | Yes | Yes | Partial | Partial | Checkov / Terrascan |

### Top 5 Critical Findings With Remediation Examples

1. **Publicly accessible RDS / DB instances (`publicly_accessible = true`)**:
   * Ensure DB provisioning modules set `publicly_accessible: false` or configure the cloud provider console to block public access.

   **Remediation:**

   - **Terraform:**
     ```terraform
      publicly_accessible  = false
     ```

   - **Pulumi (YAML):**
     ```yaml
      publiclyAccessible: false
     ```

2. **Open Security Groups (`Ingress/Egress 0.0.0.0/0`)**:
   * Use least-privilege network rules, security group references instead of wide CIDRs.

   **Remediation (Terraform example):**
   ```terraform
    cidr_blocks = ["10.0.1.0/24"]  # <--- restrict
   ```

3. **Unencrypted resources at rest (RDS `storage_encrypted=false`, DynamoDB missing `serverSideEncryption`)**:
   * Make storages encrypted or enable server-side encryption.

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

4. **Hardcoded secrets in source (API keys, DB passwords)**:
   * Move secrets to remote state or use variables from secret stores (e.g., AWS SSM)

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

5. **Overly permissive IAM policies (`"Action": ["*"]` or `"Resource":"*"`)**:
   * Apply least privilege; use IAM roles for services; require review & approval for any policy that expands scope.

   **Remediation (Terraform example):**
   ```terraform
   resource "aws_iam_policy" "s3_read_only" {
     name   = "s3_read_only"
     policy = data.aws_iam_policy_document.s3_read_only.json
   }
   ```

### Tool Strengths — What Each Tool Excels at Detecting

* **tfsec:**
   1. Highly accurate Terraform-specific checks.
   2. Low noise, developer-friendly output with precise file+line reporting.
   3. Great for fast developer pre-commit/PR checks.

* **Checkov:**
   1. Excellent for compliance and policy-as-code.
   2. Large set of built-in benchmarks and multi-IaC support.
   3. Great for CI/CD gates and regulatory requirements.

* **Terrascan:**
   1. Strong AWS-specific rule coverage.
   2. Strong mapping to compliance frameworks, good for enterprise baselines.

* **KICS:**
   1. Supports Pulumi YAML and Ansible natively; unique strength in secret detection.
   2. Fast scanning, easy to run in CI, and good multi-language IaC coverage.

**Combined approach recommendation:** use tfsec for developer feedback, Checkov/Terrascan for compliance and pipeline enforcement, and KICS for Pulumi/Ansible + secrets scanning. Combine tools in a layered pipeline.

### Lessons Learned & Limitations

* **No single tool catches everything.** Use layered detection: developer tooling (fast + low noise) + CI tools (compliance, deeper checks).
* **Dynamic IaC (Pulumi):** static scanning (Pulumi YAML) helps, but code-level checks are required.
* **Secrets in code** require specialized scanning — standard Terraform scanners may miss secrets embedded in other files.
* **False positives** occur with some compliance checks.

### Tool Selection Guide & Recommendations

1. **Developer pre-commit & PR checks (fast feedback):** tfsec + KICS (for Pulumi/Ansible).
2. **Enterprise policy & compliance gate:** Checkov (benchmarks) + Terrascan (OPA mapping).
3. **Secret scanning:** KICS + git-secrets.

**Pipeline recommendation:**
* tfsec on PR (fast) -> Checkov/Terrascan/KICS in CI.
