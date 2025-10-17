# Lab 6

## vl.kuznetsov@innopolis.university

## Task 1 — Terraform & Pulumi Security Scanning

This section summarizes the IaC security scans performed with **tfsec**, **Checkov**, **Terrascan**, and **KICS**.  
It includes finding counts, representative issues, and comparative insights.

---

### Terraform Tool Comparison (tfsec vs Checkov vs Terrascan)

**Totals**

| Tool          | Findings                                                | Notes                                            |
|---------------|---------------------------------------------------------|--------------------------------------------------|
| **tfsec**     | **53** total — CRITICAL 9 • HIGH 25 • MEDIUM 11 • LOW 8 | Terraform-specific rules, clear severity mapping |
| **Checkov**   | **78** failed checks                                    | Largest ruleset, rich policy coverage            |
| **Terrascan** | **22** violated policies — HIGH 14 • MEDIUM 8           | OPA-based, compliance-style output               |

**Quick take:**  
tfsec delivers fast, readable Terraform results with accurate severities.  
Checkov identifies the most issues overall and provides deep policy coverage.  
Terrascan surfaces compliance and governance violations mapped to frameworks.

---

### Pulumi Security Analysis (KICS)

| Metric             | Count |
|--------------------|------:|
| **Total findings** | **6** |
| - HIGH             |     2 |
| - MEDIUM           |     2 |
| - INFO             |     2 |

**Notable KICS (Pulumi) Issues**

- **KICS** `b6a7e0ae-…` (HIGH): DynamoDB table missing `serverSideEncryption`. _File:_ `Pulumi-vulnerable.yaml:205` →
  Enable SSE.
- **KICS** `647de8aa-…` (MEDIUM): RDS instance `publiclyAccessible: true`. _File:_ `Pulumi-vulnerable.yaml:104` → Set to
  false and encrypt storage.

---

### Top Critical / High Findings (Cross-Tool Highlights)

#### Network Exposure & Ingress/Egress

- **tfsec** `AVD-AWS-0107` (CRITICAL): `aws_security_group.database_exposed` — ingress 0.0.0.0/0. _File:_
  `security_groups.tf:75-83` → Restrict CIDR/ports.
- **tfsec** `AVD-AWS-0104` (CRITICAL): egress 0.0.0.0/0 rules in multiple SGs. → Limit outbound CIDRs.

#### Data Protection & Storage

- **tfsec** `AVD-AWS-0082` (CRITICAL): `aws_db_instance.unencrypted_db` — unencrypted public DB. _File:_
  `database.tf:17` → Enable storage encryption.
- **Terrascan** `AC_AWS_0210/0496` (HIGH): `aws_s3_bucket.public_data` — public ACL + missing block. _File:_
  `main.tf:13` → Block public access.
- **Terrascan** `AC_AWS_0052` (HIGH): `aws_db_instance` — backups disabled. → Set `backup_retention_period > 0`.

#### Database Hardening (Terraform)

- **Checkov** `CKV_AWS_16 / 17 / 118 / 129 / 133 / 161` — RDS instance unencrypted, publicly accessible, no backups.
  _File:_ `database.tf` → Apply encryption, private networking, and backups.

---

### Terraform vs Pulumi Observations

- **Overlap:** Encryption-at-rest and public exposure issues appear in both stacks.
- **Difference:** Pulumi YAML findings focus on application-layer configs (`publiclyAccessible`, SSE), while Terraform
  findings span IAM and network policies.
- **Insight:** Declarative Terraform code exposes infrastructure defaults; Pulumi’s imperative YAML needs strong secret
  management and encryption settings.

---

### Remediation Highlights

- **S3 Buckets:** Enable versioning and server-side encryption; block public ACLs/policies.
- **RDS:** `storage_encrypted = true`, `publicly_accessible = false`, enable backups and log exports.
- **Security Groups:** Avoid `0.0.0.0/0`; restrict CIDRs/ports to least privilege.
- **Secrets:** Replace hardcoded credentials with Secrets Manager or Pulumi config secrets.
- **Compliance:** Integrate Checkov and Terrascan in CI/CD for ongoing policy enforcement.

## Task 2 — Ansible Security Scanning (KICS)

This task analyzed the vulnerable Ansible playbooks using **KICS** to identify misconfigurations, hard-coded secrets,
and weak supply-chain practices.

---

### Scan Summary

| Metric               | Count |
|:---------------------|------:|
| **Files scanned**    |     3 |
| **Lines scanned**    |   309 |
| **Queries executed** |   287 |
| **Total findings**   | **9** |
| • HIGH               |     8 |
| • MEDIUM             |     0 |
| • LOW                |     1 |
| • CRITICAL / INFO    |     0 |

_Source: `labs/lab6/analysis/kics-ansible-results.json` and `kics-ansible-report.txt`_

---

### Top Detected Issues

| Severity | Query ID / Rule Name                                        | File / Line                                                        | Category          | Description / Remediation                                                                                                      |
|:---------|:------------------------------------------------------------|:-------------------------------------------------------------------|:------------------|:-------------------------------------------------------------------------------------------------------------------------------|
| **HIGH** | `487f4be7-…` – **Passwords and Secrets – Generic Password** | `inventory.ini:5, 10, 18, 19`; `configure.yml:16`; `deploy.yml:12` | Secret Management | Hard-coded passwords / secrets in playbooks and inventory files. → Use Ansible Vault or environment variables for credentials. |
| **HIGH** | `c4d3b58a-…` – **Passwords and Secrets – Password in URL**  | `deploy.yml:16, 72`                                                | Secret Management | Sensitive credentials embedded in URLs. → Use vaulted variables and secure lookups instead of inline strings.                  |
| **LOW**  | `c05e2c20-…` – **Unpinned Package Version**                 | `deploy.yml:99`                                                    | Supply-Chain      | Task installs packages with `state: latest`, causing uncontrolled upgrades. → Pin package versions or set `update_only: true`. |

---

### Analysis & Observations

- **Secrets management** issues dominate (8 of 9 findings).  
  Credentials appear hard-coded in multiple playbooks and inventory files.
- **Supply-chain** hygiene: one instance of un-pinned package installation could break builds or cause inconsistent
  deployments.
- **No CRITICAL/MEDIUM** issues detected; however, the secret findings are severe from a real-world risk standpoint.
- Compared to Terraform and Pulumi scans, the Ansible scan revealed developer workflow risks (secrets handling and
  package management) rather than resource configuration flaws.

---

### Recommended Remediations

1. **Use Ansible Vault** to encrypt passwords, tokens, and API keys.
2. **Replace inline URLs with passwords** using `lookup('env', 'VAR_NAME')` or `vars_prompt`.
3. **Pin package versions** (e.g., `version: 1.2.3`) and avoid `state: latest`.
4. **Integrate KICS into CI/CD** to automatically scan playbooks on commit.
5. **Apply role-based access controls** to limit who can modify vaulted files.

## Task 3 — Comparative Tool Analysis & Security Insights


### Summary of Findings
| Tool               | Framework | Findings |
|:-------------------|:----------|---------:|
| **tfsec**          | Terraform |   **53** |
| **Checkov**        | Terraform |   **78** |
| **Terrascan**      | Terraform |   **22** |
| **KICS (Pulumi)**  | Pulumi    |    **6** |
| **KICS (Ansible)** | Ansible   |    **9** |

_Source: `labs/lab6/analysis/tool-comparison.txt`_

---

### Tool Effectiveness Matrix

| Criterion             |                      tfsec                      |               Checkov               |          Terrascan          |                  KICS                   |
|-----------------------|:-----------------------------------------------:|:-----------------------------------:|:---------------------------:|:---------------------------------------:|
| **Total Findings**    |                       53                        |                 78                  |             22              |          15 (Pulumi + Ansible)          |
| **Scan Speed**        |                     ⚡ Fast                      |               ⚡ Fast                |          🕐 Medium          |                🕐 Medium                |
| **False Positives**   |                       Low                       |               Medium                |           Medium            |                   Low                   |
| **Report Quality**    |                      ⭐⭐⭐⭐                       |                ⭐⭐⭐⭐                 |             ⭐⭐⭐             |                   ⭐⭐⭐                   |
| **Ease of Use**       |                      ⭐⭐⭐⭐                       |                 ⭐⭐⭐                 |             ⭐⭐              |                   ⭐⭐⭐                   |
| **Documentation**     |                       ⭐⭐⭐                       |                ⭐⭐⭐⭐                 |             ⭐⭐⭐             |                  ⭐⭐⭐⭐                   |
| **Platform Support**  |                 Terraform only                  | Multi (Terraform, CFN, K8s, Docker) |   Multi (Terraform, K8s)    | Multi (Terraform, Pulumi, Ansible, K8s) |
| **Output Formats**    |                JSON, Text, SARIF                |          JSON, CLI, SARIF           |      JSON, YAML, Human      |            JSON, HTML, SARIF            |
| **CI/CD Integration** |                      Easy                       |                Easy                 |           Medium            |                  Easy                   |
| **Unique Strengths**  | Fast Terraform scanning, clean severity mapping |   Broad multi-framework coverage    | OPA-based compliance checks |  First-class Pulumi & Ansible support   |

---

### 🧠 Vulnerability Category Analysis

| Security Category               | tfsec | Checkov | Terrascan | KICS (Pulumi) | KICS (Ansible) | 🏆 Best Tool            |
|---------------------------------|:-----:|:-------:|:---------:|:-------------:|:--------------:|:------------------------|
| **Encryption Issues**           |   ✅   |   ✅✅    |     ✅     |       ✅       |      N/A       | **Checkov**             |
| **Network Security**            |  ✅✅   |    ✅    |     ✅     |       ✅       |      N/A       | **tfsec**               |
| **Secrets Management**          |   ✅   |   ✅✅    |     ⚪     |       ✅       |       ✅✅       | **KICS (Ansible)**      |
| **IAM / Permissions**           |   ✅   |   ✅✅    |     ⚪     |       ⚪       |      N/A       | **Checkov**             |
| **Access Control**              |   ✅   |    ✅    |    ✅✅     |       ✅       |       ⚪        | **Terrascan**           |
| **Compliance / Best Practices** |   ⚪   |   ✅✅    |    ✅✅     |       ✅       |       ⚪        | **Terrascan / Checkov** |

**Legend:**  
✅ = detects | ✅✅ = strong detection | ⚪ = limited support

---

### Top 5 Critical Findings (Cross-Tool Highlights)

| Tool               | Category           | Example Finding                                           | Risk                             | Recommended Fix                             |
|--------------------|--------------------|-----------------------------------------------------------|----------------------------------|---------------------------------------------|
| **tfsec**          | Network Security   | `aws_security_group.database_exposed` (0.0.0.0/0 ingress) | Public DB exposure               | Restrict CIDRs and ports to known IPs.      |
| **Checkov**        | Data Protection    | `CKV_AWS_17` – Unencrypted RDS instance                   | Data theft if snapshot leaked    | Add `storage_encrypted = true` and KMS key. |
| **Terrascan**      | Compliance         | `AC_AWS_0052` – RDS backups disabled                      | Data loss on failure             | Set `backup_retention_period > 0`.          |
| **KICS (Pulumi)**  | Encryption         | DynamoDB table missing SSE                                | Violation of data-at-rest policy | Enable `serverSideEncryption: true`.        |
| **KICS (Ansible)** | Secrets Management | Hardcoded passwords in `inventory.ini`                    | Credential leakage               | Use Ansible Vault or secret lookups.        |

---

### Tool Selection Guide

| Use Case                                | Recommended Tool(s)  | Rationale                                                   |
|:----------------------------------------|:---------------------|:------------------------------------------------------------|
| **Fast CI/CD Terraform scanning**       | **tfsec**            | Lightweight, minimal setup, low false positives.            |
| **Comprehensive IaC policy coverage**   | **Checkov**          | Broad support for Terraform, K8s, Docker, CloudFormation.   |
| **Compliance / Governance enforcement** | **Terrascan**        | OPA-based policy engine aligned with PCI-DSS, HIPAA, CIS.   |
| **Pulumi & Ansible security scanning**  | **KICS (Checkmarx)** | Native query catalog for Pulumi YAML and Ansible playbooks. |
| **Unified multi-framework scanning**    | **KICS + Checkov**   | Combined approach covers all IaC formats consistently.      |

---

### 🔒 Lessons Learned

- **No single tool covers all IaC frameworks** — combining scanners ensures full visibility.
- **tfsec** is ideal for early Terraform validation with minimal overhead.
- **Checkov** offers the broadest rule coverage but requires tuning to reduce false positives.
- **Terrascan** excels in compliance mapping but runs slower and outputs verbose reports.
- **KICS** brings Pulumi and Ansible into the same security workflow, enabling cross-framework consistency.
- **Overlap is beneficial** — shared findings confirm true issues, while unique ones highlight gaps between tools.

---

### CI/CD Integration Strategy

**Recommended multi-stage pipeline:**

1. **Pre-commit hooks:** Run `tfsec` and `Checkov` locally to catch Terraform issues early.
2. **Pull request stage:** Execute full scans — `Checkov`, `Terrascan`, and `KICS` — as CI jobs.
3. **Post-deployment / nightly:** Run compliance-focused `Terrascan` scans across all IaC repositories.
4. **Alerting:** Push JSON/SARIF results to dashboards (e.g., GitHub Security, SonarQube, or DefectDojo).
5. **Policy gating:** Fail CI builds for any CRITICAL/HIGH issues detected.