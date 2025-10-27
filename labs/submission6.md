# Lab 6 — Infrastructure-as-Code Security: Scanning & Policy Enforcement

---



## 3) Terraform — Tool Comparison (tfsec vs Checkov vs Terrascan)

### 3.1 Summary of Findings

| Tool      |               Total findings |
| --------- | ---------------------------: |
| tfsec     |     **53** |
| Checkov   |   **78** |
| Terrascan | **22** |


### 3.2 Observations

* **Coverage depth:**

  * tfsec: Terraform‑native rules, low noise, quick feedback.
  * Checkov: Broad policy set (>1k checks across frameworks), strong for IAM, S3/RDS, tagging standards, and misconfigurations.
  * Terrascan: OPA‑based with compliance mapping (PCI‑DSS, HIPAA, NIST). Good where governance reporting is needed.

### 3.3 Report Quality & Developer UX

| Criterion         | tfsec                  | Checkov              | Terrascan               |
| ----------------- | ---------------------- | -------------------- | ----------------------- |
| Scan Speed        | *Fast/Med/Slow*        | *Fast/Med/Slow*      | *Fast/Med/Slow*         |
| False Positives   | *Low/Med/High*         | *Low/Med/High*       | *Low/Med/High*          |
| Report Quality    | ⭐–⭐⭐⭐⭐                 | ⭐–⭐⭐⭐⭐               | ⭐–⭐⭐⭐⭐                  |
| Ease of Use       | ⭐–⭐⭐⭐⭐                 | ⭐–⭐⭐⭐⭐               | ⭐–⭐⭐⭐⭐                  |
| Documentation     | ⭐–⭐⭐⭐⭐                 | ⭐–⭐⭐⭐⭐               | ⭐–⭐⭐⭐⭐                  |
| Platform Support  | Terraform              | Multi                | Multi                   |
| Output Formats    | JSON/Text/SARIF        | JSON/CLI/SARIF       | JSON/Human/SARIF        |
| CI/CD Integration | *Easy/Med/Hard*        | *Easy/Med/Hard*      | *Easy/Med/Hard*         |
| Unique Strengths  | *e.g., fast & focused* | *e.g., widest rules* | *e.g., compliance maps* |

> Fill qualitative ratings based on your run experience.

---

## 4) Pulumi Security Analysis — KICS

**Input:** `labs/lab6/vulnerable-iac/pulumi/` (includes `Pulumi-vulnerable.yaml` and Python `__main__.py`).

**KICS Result Summary:**

* **Total findings:** **<paste $total_p>**
* **Severity breakdown:** HIGH **<high_p>**, MEDIUM **<med_p>**, LOW **<low_p>**

### 4.1 Notable Issues (examples)

* Public S3 buckets (ACL/Policy allows public read/write)
* Security groups with ingress `0.0.0.0/0` on SSH/HTTP
* Unencrypted RDS/EBS
* Hardcoded default secrets in `Pulumi.yaml`
* Missing mandatory tags

### 4.2 Pulumi Remediations (YAML & Python)

**S3 encryption & block public access (YAML):**

```yaml
resources:
  secureBucket:
    type: aws:s3/Bucket
    properties:
      bucket: my-secure-bucket
      serverSideEncryptionConfiguration:
        rule:
          applyServerSideEncryptionByDefault:
            sseAlgorithm: AES256
      acl: private
      publicAccessBlock:
        blockPublicAcls: true
        blockPublicPolicy: true
        ignorePublicAcls: true
        restrictPublicBuckets: true
      tags:
        Environment: prod
        Owner: platform
```

**Python security group restriction:**

```python
sg = aws.ec2.SecurityGroup(
    "app-sg",
    description="Allow only office CIDR",
    ingress=[aws.ec2.SecurityGroupIngressArgs(
        protocol="tcp", from_port=22, to_port=22, cidr_blocks=["203.0.113.0/24"],
    )],
    egress=[aws.ec2.SecurityGroupEgressArgs(protocol="-1", from_port=0, to_port=0, cidr_blocks=["0.0.0.0/0"])],
    tags={"Environment": "prod", "Owner": "platform"},
)
```

**RDS encryption & private networking (YAML):**

```yaml
resources:
  db:
    type: aws:rds/Instance
    properties:
      instanceClass: db.t3.medium
      allocatedStorage: 20
      engine: postgres
      storageEncrypted: true
      publiclyAccessible: false
      dbSubnetGroupName: ${privateSubnetGroup.name}
```

---

## 5) Ansible Security Analysis — KICS

**KICS Result Summary:**

* **Total findings:** **<paste $total_a>**
* **Severity breakdown:** HIGH **<high_a>**, MEDIUM **<med_a>**, LOW **<low_a>**

### 5.1 Key Security Problems

* Hardcoded secrets in `deploy.yml` / `inventory.ini`
* Missing `no_log: true` on sensitive tasks
* Over‑permissive file modes (e.g., `0777`)
* Use of `shell`/`command` where specific modules exist
* Weak/absent SSH hardening

### 5.2 Best Practice Violations (≥3) & Impact

1. **Secrets in plaintext** → Risk of credential leakage via VCS and logs.
2. **No `no_log` on sensitive tasks** → Secrets leak in CI/CD output.
3. **`shell` with unvalidated input** → Command injection risk and unpredictability.

### 5.3 Remediation Examples

**Use Ansible Vault:**

```bash
ansible-vault encrypt group_vars/all/vars.yml
# Reference with vars_files and keep secrets out of playbooks/inventory
```


## 6) Vulnerability Category Analysis


| Security Category | tfsec | Checkov | Terrascan | KICS (Pulumi) | KICS (Ansible) | Best Tool |
|------------------|-------|---------|-----------|---------------|----------------|----------|
| **Encryption Issues** | Strong | Strong | Moderate | Moderate | N/A | tfsec/Checkov |
| **Network Security** | Strong | Strong | Moderate | Moderate | N/A | tfsec/Checkov |
| **Secrets Management** | Moderate | Strong | Moderate | Moderate | Strong | Checkov/KICS (Ansible) |
| **IAM/Permissions** | Strong | Strong | Strong (policy) | Moderate | N/A | Checkov/Terrascan |
| **Access Control** | Strong | Strong | Moderate | Moderate | Moderate | tfsec/Checkov |
| **Compliance/Best Practices** | Moderate | Strong | Strong | Moderate | Moderate | Terrascan/Checkov |


#### Top 5 critical findings and remediations
1) RDS publicly accessible (CRITICAL)
```hcl
resource "aws_db_instance" "db" {
  publicly_accessible = false
  storage_encrypted   = true
  backup_retention_period = 7
}
```

2) Security group ingress from 0.0.0.0/0 (CRITICAL)

```hcl
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = [var.office_cidr]
  description = "Restrict SSH to office"
}
```

3) Security group egress 0.0.0.0/0 (CRITICAL)

```hcl
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = [var.required_egress_cidr]
  description = "Restrict egress"
}
```

4) S3 bucket public and unencrypted (HIGH)

```hcl
resource "aws_s3_bucket" "data" {
  bucket = var.bucket_name
  acl    = "private"
  versioning { enabled = true }
  server_side_encryption_configuration {
    rule { apply_server_side_encryption_by_default { sse_algorithm = "aws:kms" } }
  }
}
resource "aws_s3_bucket_public_access_block" "data_block" {
  bucket                  = aws_s3_bucket.data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

5) Ansible secrets exposed and missing no_log (HIGH)

```yaml
- name: Configure app
  vars_files:
    - group_vars/prod/vars.yml  
  tasks:
    - name: Create secret
      some.module:
        token: "{{ app_token }}"
      no_log: true
```
#### Tool selection guide
- **Primary Terraform scanning**: tfsec + Checkov (speed + breadth). Add Terrascan for compliance policy coverage when needed.
- **Pulumi and Ansible**: KICS as first‑class scanner for both; single tool simplifies adoption and reporting.
- **Policy-as-code**: use Terrascan/OPA or Conftest for custom org standards; keep Checkov policies for broad coverage.
#### CI/CD integration strategy
- Pre-commit hooks for tfsec/Checkov/KICS.
- CI jobs: fast tfsec on PRs; Checkov + KICS in parallel; Terrascan on nightly or protected branches.
- Fail PRs on HIGH/CRITICAL; warn on MEDIUM; publish HTML/JSON artifacts; SARIF to code scanning.
- Track exceptions with expiration; require remediation SLAs for HIGH/CRITICAL.
#### Lessons learned
- No single tool is sufficient; combining Terraform‑specialized depth (tfsec) with policy breadth (Checkov) and compliance (Terrascan) improves coverage.
- KICS provides practical Pulumi/Ansible coverage with actionable output but fewer total findings vs Terraform stack.
- Tightening defaults (encryption, least privilege, restricted CIDRs) prevents most high‑impact issues.