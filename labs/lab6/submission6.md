## Task 1 — Terraform & Pulumi Security Scanning (5 pts)

### 1.1 Setup Scanning Environment

```bash
# Create analysis directory for all scan results
mkdir -p labs/lab6/analysis
```

<details>
<summary>Vulnerable IaC Code Structure</summary>

**Location:** `labs/lab6/vulnerable-iac/`

**Terraform** (`terraform/`): public S3, permissive SGs (0.0.0.0/0), unencrypted RDS, wildcard IAM, insecure defaults.
**Pulumi** (`pulumi/`): `__main__.py`, `Pulumi.yaml`, `Pulumi-vulnerable.yaml` (public S3, open SGs, unencrypted DBs).
**Ansible** (`ansible/`): hardcoded secrets, weak SSH config, plaintext inventory.

> Total: 80+ intentionally vulnerable resources across frameworks.

</details>

---

### 1.2 Scan Terraform with tfsec

```bash
# JSON report
docker run --rm -v "$(pwd)/labs/lab6/vulnerable-iac/terraform":/src \
  aquasec/tfsec:latest /src \
  --format json > labs/lab6/analysis/tfsec-results.json

# Human-readable report
docker run --rm -v "$(pwd)/labs/lab6/vulnerable-iac/terraform":/src \
  aquasec/tfsec:latest /src > labs/lab6/analysis/tfsec-report.txt
```

---

### 1.3 Scan Terraform with Checkov

```bash
# JSON
docker run --rm -v "$(pwd)/labs/lab6/vulnerable-iac/terraform":/tf \
  bridgecrew/checkov:latest \
  -d /tf --framework terraform \
  -o json > labs/lab6/analysis/checkov-terraform-results.json

# Compact text
docker run --rm -v "$(pwd)/labs/lab6/vulnerable-iac/terraform":/tf \
  bridgecrew/checkov:latest \
  -d /tf --framework terraform \
  --compact > labs/lab6/analysis/checkov-terraform-report.txt
```

---

### 1.4 Scan Terraform with Terrascan

```bash
# JSON
docker run --rm -v "$(pwd)/labs/lab6/vulnerable-iac/terraform":/iac \
  tenable/terrascan:latest scan \
  -i terraform -d /iac \
  -o json > labs/lab6/analysis/terrascan-results.json

# Human-readable
docker run --rm -v "$(pwd)/labs/lab6/vulnerable-iac/terraform":/iac \
  tenable/terrascan:latest scan \
  -i terraform -d /iac \
  -o human > labs/lab6/analysis/terrascan-report.txt
```

---

### 1.5 Terraform Scanning Analysis

Counts aggregated with `jq` into `labs/lab6/analysis/terraform-comparison.txt`.

**Terraform Tool Comparison (tfsec vs Checkov vs Terrascan)**

| Tool          | Findings                                                | Notes                                            |
| ------------- | ------------------------------------------------------- | ------------------------------------------------ |
| **tfsec**     | **53** total — CRITICAL 9 • HIGH 25 • MEDIUM 11 • LOW 8 | Terraform-specific rules, clear severity mapping |
| **Checkov**   | **78** failed checks                                    | Largest ruleset, rich policy coverage            |
| **Terrascan** | **22** violated policies — HIGH 14 • MEDIUM 8           | OPA-based, compliance-style output               |

**Highlights (Terraform):**

* **Network exposure**: `AVD-AWS-0107` (CRITICAL) — SG ingress `0.0.0.0/0` (`security_groups.tf:75–83`).
* **Open egress**: `AVD-AWS-0104` (CRITICAL) — egress `0.0.0.0/0` in multiple SGs.
* **Data at rest**: `AVD-AWS-0082` (CRITICAL) — unencrypted public RDS (`database.tf:17`).
* **S3 public**: Terrascan `AC_AWS_0210/0496` (HIGH) — public ACL + missing public access block (`main.tf:13`).
* **Backups off**: Terrascan `AC_AWS_0052` (HIGH) — RDS backups disabled.

---

### 1.6 Scan Pulumi with KICS (Checkmarx)

```bash
# JSON + HTML
docker run -t --rm -v "$(pwd)/labs/lab6/vulnerable-iac/pulumi":/src \
  checkmarx/kics:latest \
  scan -p /src -o /src/kics-report --report-formats json,html

# Move reports to analysis
sudo mv labs/lab6/vulnerable-iac/pulumi/kics-report/results.json labs/lab6/analysis/kics-pulumi-results.json
sudo mv labs/lab6/vulnerable-iac/pulumi/kics-report/results.html labs/lab6/analysis/kics-pulumi-report.html

# Console summary
docker run -t --rm -v "$(pwd)/labs/lab6/vulnerable-iac/pulumi":/src \
  checkmarx/kics:latest \
  scan -p /src --minimal-ui > labs/lab6/analysis/kics-pulumi-report.txt 2>&1 || true
```

**Pulumi Security Analysis (KICS)**

| Metric             | Count |
| ------------------ | ----: |
| **Total findings** | **6** |
| - HIGH             |     2 |
| - MEDIUM           |     2 |
| - INFO             |     2 |

**Representative Issues (Pulumi YAML):**

* `b6a7e0ae-…` (HIGH): DynamoDB missing `serverSideEncryption` — `Pulumi-vulnerable.yaml:205` → enable SSE.
* `647de8aa-…` (MEDIUM): RDS `publiclyAccessible: true` — `Pulumi-vulnerable.yaml:104` → set `false`, encrypt storage.

---

### Terraform vs Pulumi — Key Observations

* **Overlap:** encryption-at-rest & public exposure issues in both stacks.
* **Differences:** Pulumi findings skew to resource flags (SSE, `publiclyAccessible`), Terraform also hits IAM/networking.
* **Takeaway:** Terraform’s declarative HCL surfaces infra defaults; Pulumi demands explicit secret handling and encryption config.

---

### Remediation Highlights (Code-Level)

* **S3**: enable versioning + SSE; block public ACLs/policies.
* **RDS**: `storage_encrypted = true`, `publicly_accessible = false`, backups + log exports.
* **SGs**: avoid `0.0.0.0/0`; restrict CIDRs/ports.
* **Secrets**: remove hardcoded creds; use AWS Secrets Manager / Pulumi config secrets.
* **Pipeline**: enforce Checkov/Terrascan in CI with severity gating.

---

## Task 2 — Ansible Security Scanning with KICS (2 pts)

### 2.1 Run KICS on Ansible

```bash
# JSON + HTML
docker run -t --rm -v "$(pwd)/labs/lab6/vulnerable-iac/ansible":/src \
  checkmarx/kics:latest \
  scan -p /src -o /src/kics-report --report-formats json,html

# Move reports
sudo mv labs/lab6/vulnerable-iac/ansible/kics-report/results.json labs/lab6/analysis/kics-ansible-results.json
sudo mv labs/lab6/vulnerable-iac/ansible/kics-report/results.html labs/lab6/analysis/kics-ansible-report.html

# Console summary
docker run -t --rm -v "$(pwd)/labs/lab6/vulnerable-iac/ansible":/src \
  checkmarx/kics:latest \
  scan -p /src --minimal-ui > labs/lab6/analysis/kics-ansible-report.txt 2>&1 || true
```

---

### 2.2 Ansible Security Analysis

`labs/lab6/analysis/ansible-analysis.txt` contains the counters aggregated with `jq`.

**Scan Summary**

| Metric               | Count |
| :------------------- | ----: |
| **Files scanned**    |     3 |
| **Lines scanned**    |   309 |
| **Queries executed** |   287 |
| **Total findings**   | **9** |
| • HIGH               |     8 |
| • MEDIUM             |     0 |
| • LOW                |     1 |
| • CRITICAL / INFO    |     0 |

**Top Detected Issues**

| Severity | Query ID / Rule Name                                        | File / Line                                                        | Category          | Description / Remediation                                                                               |
| :------- | :---------------------------------------------------------- | :----------------------------------------------------------------- | :---------------- | :------------------------------------------------------------------------------------------------------ |
| **HIGH** | `487f4be7-…` – **Passwords and Secrets – Generic Password** | `inventory.ini:5, 10, 18, 19`; `configure.yml:16`; `deploy.yml:12` | Secret Management | Hardcoded passwords/secrets → store in **Ansible Vault** or env vars; remove from inventory/playbooks.  |
| **HIGH** | `c4d3b58a-…` – **Passwords and Secrets – Password in URL**  | `deploy.yml:16, 72`                                                | Secret Management | Credentials in URLs → replace with vaulted variables and secure lookups (e.g., `lookup('env', 'VAR')`). |
| **LOW**  | `c05e2c20-…` – **Unpinned Package Version**                 | `deploy.yml:99`                                                    | Supply-Chain      | `state: latest` causes uncontrolled upgrades → pin versions or use `update_only: true`.                 |

**Best Practice Violations (examples & impact)**

1. **Secrets in plaintext** (playbooks/inventory) → immediate credential leakage risk.
2. **Credentials in URLs** → exposed in logs and process lists → lateral movement risk.
3. **Unpinned packages** → non-deterministic builds, possible supply-chain compromise.

**Remediation Steps**

1. Encrypt secrets with **Ansible Vault** (`ansible-vault encrypt vars.yml`), reference via vars.
2. Use `no_log: true` on sensitive tasks; replace inline URLs with vaulted creds or `lookup('env', ...)`.
3. Pin versions (`version: 1.2.3`), avoid `state: latest`; prefer modules over `shell/command` where possible.

---

## Task 3 — Comparative Tool Analysis & Security Insights (3 pts)

### 3.1 Comprehensive Tool Comparison

**Summary of Findings**

| Tool               | Framework | Findings |
| :----------------- | :-------- | -------: |
| **tfsec**          | Terraform |   **53** |
| **Checkov**        | Terraform |   **78** |
| **Terrascan**      | Terraform |   **22** |
| **KICS (Pulumi)**  | Pulumi    |    **6** |
| **KICS (Ansible)** | Ansible   |    **9** |

*Source: `labs/lab6/analysis/tool-comparison.txt`*

**Tool Effectiveness Matrix**

| Criterion             |                      tfsec                      |               Checkov               |          Terrascan          |                   KICS                  |
| --------------------- | :---------------------------------------------: | :---------------------------------: | :-------------------------: | :-------------------------------------: |
| **Total Findings**    |                        53                       |                  78                 |              22             |          15 (Pulumi + Ansible)          |
| **Scan Speed**        |                      ⚡ Fast                     |                ⚡ Fast               |          🕐 Medium          |                🕐 Medium                |
| **False Positives**   |                       Low                       |                Medium               |            Medium           |                   Low                   |
| **Report Quality**    |                       ⭐⭐⭐⭐                      |                 ⭐⭐⭐⭐                |             ⭐⭐⭐             |                   ⭐⭐⭐                   |
| **Ease of Use**       |                       ⭐⭐⭐⭐                      |                 ⭐⭐⭐                 |              ⭐⭐             |                   ⭐⭐⭐                   |
| **Documentation**     |                       ⭐⭐⭐                       |                 ⭐⭐⭐⭐                |             ⭐⭐⭐             |                   ⭐⭐⭐⭐                  |
| **Platform Support**  |                  Terraform only                 | Multi (Terraform, CFN, K8s, Docker) |    Multi (Terraform, K8s)   | Multi (Terraform, Pulumi, Ansible, K8s) |
| **Output Formats**    |                JSON, Text, SARIF                |           JSON, CLI, SARIF          |      JSON, YAML, Human      |            JSON, HTML, SARIF            |
| **CI/CD Integration** |                       Easy                      |                 Easy                |            Medium           |                   Easy                  |
| **Unique Strengths**  | Fast Terraform scanning, clean severity mapping |    Broad multi-framework coverage   | OPA-based compliance checks |   First-class Pulumi & Ansible support  |

---

### 3.2 Vulnerability Category Analysis

| Security Category               | tfsec | Checkov | Terrascan | KICS (Pulumi) | KICS (Ansible) | 🏆 Best Tool            |
| ------------------------------- | :---: | :-----: | :-------: | :-----------: | :------------: | :---------------------- |
| **Encryption Issues**           |   ✅   |    ✅✅   |     ✅     |       ✅       |       N/A      | **Checkov**             |
| **Network Security**            |   ✅✅  |    ✅    |     ✅     |       ✅       |       N/A      | **tfsec**               |
| **Secrets Management**          |   ✅   |    ✅✅   |     ⚪     |       ✅       |       ✅✅       | **KICS (Ansible)**      |
| **IAM / Permissions**           |   ✅   |    ✅✅   |     ⚪     |       ⚪       |       N/A      | **Checkov**             |
| **Access Control**              |   ✅   |    ✅    |     ✅✅    |       ✅       |        ⚪       | **Terrascan**           |
| **Compliance / Best Practices** |   ⚪   |    ✅✅   |     ✅✅    |       ✅       |        ⚪       | **Terrascan / Checkov** |

**Legend:** ✅ = detects | ✅✅ = strong detection | ⚪ = limited

---

### Top 5 Critical Findings (with Fix Guidance)

| Tool               | Category           | Example Finding                                           | Risk                     | Recommended Fix                       |
| ------------------ | ------------------ | --------------------------------------------------------- | ------------------------ | ------------------------------------- |
| **tfsec**          | Network Security   | `aws_security_group.database_exposed` (0.0.0.0/0 ingress) | Public DB exposure       | Restrict CIDRs/ports to known IPs.    |
| **Checkov**        | Data Protection    | `CKV_AWS_17` – Unencrypted RDS instance                   | Data theft via snapshots | `storage_encrypted = true` + KMS key. |
| **Terrascan**      | Compliance         | `AC_AWS_0052` – RDS backups disabled                      | Data loss on failure     | `backup_retention_period > 0`.        |
| **KICS (Pulumi)**  | Encryption         | DynamoDB lacks SSE                                        | At-rest policy violation | `serverSideEncryption: true`.         |
| **KICS (Ansible)** | Secrets Management | Hardcoded passwords in `inventory.ini`                    | Credential leakage       | Ansible Vault / secret lookups.       |

---

### Tool Selection Guide

| Use Case                                | Recommended Tool(s)  | Rationale                                                  |
| :-------------------------------------- | :------------------- | :--------------------------------------------------------- |
| **Fast CI/CD Terraform scanning**       | **tfsec**            | Lightweight, quick, low FP.                                |
| **Comprehensive IaC policy coverage**   | **Checkov**          | Broad multi-framework support + huge ruleset.              |
| **Compliance / Governance enforcement** | **Terrascan**        | OPA-based policies mapped to PCI-DSS, HIPAA, CIS.          |
| **Pulumi & Ansible security scanning**  | **KICS (Checkmarx)** | First-class Pulumi/Ansible queries and consistent outputs. |
| **Unified multi-framework coverage**    | **KICS + Checkov**   | Combined breadth + consistency across formats.             |

---

### Lessons Learned

* No single tool covers all IaC risks; **combine scanners** for best coverage.
* **tfsec** is ideal for fast Terraform checks pre-commit.
* **Checkov** finds the most issues but needs tuning for FPs.
* **Terrascan** shines in compliance contexts.
* **KICS** aligns Pulumi + Ansible with the same security workflow.
* Overlapping detections validate real issues; uniques reveal coverage gaps.
