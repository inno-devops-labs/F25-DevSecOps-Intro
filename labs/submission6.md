## Lab 6 — IaC Security: Scanning, Analysis, and Policy Insights

### Task 1 — Terraform & Pulumi Security Scanning

#### Terraform tool comparison (tfsec vs Checkov vs Terrascan)

- **Finding counts** (from `labs/lab6/analysis/terraform-comparison.txt`):
  - **tfsec**: 53
  - **Checkov**: 78
  - **Terrascan**: 22

- **What each tool excels at detecting**:
  - **Checkov** reported the most issues (broad policy catalog and multi-provider coverage), useful for depth and coverage across categories.
  - **tfsec** found many high/critical Terraform‑specific issues with clear guidance and low noise; great as a fast primary scanner.
  - **Terrascan** surfaced fewer findings but maps well to compliance-style checks (OPA/Rego), good for policy-as-code and governance alignment.

#### Representative Terraform findings (tfsec excerpts) 5 significant security issues

```1:5:labs/lab6/analysis/tfsec-report.txt
=== Terraform Security Analysis ===
tfsec findings: 53
```

```2:18:labs/lab6/analysis/tfsec-report.txt
Result #1  CRITICAL  Instance is exposed publicly.
database.tf:17  publicly_accessible = true   # SECURITY ISSUE #10 - Public access!
ID aws-rds-no-public-db-access — Set the database to not be publicly accessible
```

```22:39:labs/lab6/analysis/tfsec-report.txt
Result #2  CRITICAL  Security group rule allows ingress from public internet.
security_groups.tf:15  cidr_blocks = ["0.0.0.0/0"]
ID aws-ec2-no-public-ingress-sgr — Set a more restrictive cidr range
```

```42:59:labs/lab6/analysis/tfsec-report.txt
Result #3  CRITICAL  Security group rule allows egress to public internet.
security_groups.tf:22  cidr_blocks = ["0.0.0.0/0"]
ID aws-ec2-no-public-egress-sgr — Set a more restrictive cidr range
```

```327:347:labs/lab6/analysis/tfsec-report.txt
Result #22  HIGH  S3 bucket encryption not enabled
main.tf:13-21  aws_s3_bucket.public_data { acl = "public-read" }
ID aws-s3-enable-bucket-encryption — Configure bucket encryption
```

```549:566:labs/lab6/analysis/tfsec-report.txt
Result #31  HIGH  Public access block misconfigured (block_public_acls=false)
main.tf:39 aws_s3_bucket_public_access_block.bad_config
ID aws-s3-block-public-acls — Enable blocking public ACLs
```

#### Pulumi security analysis (KICS)

```1:6:labs/lab6/analysis/pulumi-analysis.txt
=== Pulumi Security Analysis (KICS) ===
KICS Pulumi findings: 6
  HIGH severity: 2
  MEDIUM severity: 2
  LOW severity: 0
```

- **Highlights**: Exposed storage/network paths and missing encryption surfaced. Severity distribution skews towards HIGH/MEDIUM, indicating impactful misconfigurations even with a lower total count relative to Terraform.

#### Terraform vs Pulumi

- **Overlap**: Encryption defaults, permissive security groups, public S3 exposure, and IAM over-permissions appear in both stacks.
- **Differences**: Terraform (HCL) surfaced more S3/RDS/SG hardening gaps at resource block level; Pulumi (YAML/Python) findings concentrate on configuration defaults and secret handling. Declarative HCL made misconfigurations easier for specialized Terraform rules; Pulumi relies more on KICS’ Pulumi catalog for parity.

#### KICS Pulumi support evaluation

- Pulumi YAML recognized automatically; results include severities and concise remediation text. Query coverage is sufficient for common AWS misconfigurations; good HTML/JSON outputs for pipeline use. Pulumi coverage is narrower than Terraform tools but adequate for core hygiene (network, encryption, exposure, secrets).

### Task 2 — Ansible Security Scanning with KICS

```1:6:labs/lab6/analysis/ansible-analysis.txt
=== Ansible Security Analysis (KICS) ===
KICS Ansible findings: 9
  HIGH severity: 8
  MEDIUM severity: 0
  LOW severity: 1
```

- **Key issues**:
  - Hardcoded credentials in playbooks/inventory
  - Missing `no_log: true` on sensitive tasks
  - Over-permissive file modes and shell/command usage where safer modules exist

- **KICS Ansible queries — what it checks**:
  - **Secrets management**: plaintext passwords/tokens, vars in inventory, unsafe templating in `debug`/`set_fact`, missing Vault usage.
  - **Command execution safety**: risky `shell`/`command` usage, missing `creates`/`removes`/`chdir`, unvalidated `with_items` input.
  - **File permissions & ownership**: world-writable files/dirs, improper modes for keys/configs, missing `owner`/`group`.
  - **Authentication & access control**: SSH hardening, authorized_keys management, insecure `PermitRootLogin`, weak ciphers/mac.
  - **Privilege escalation**: improper `become` usage, tasks running as root unnecessarily, missing `become_user`.
  - **Network/service hardening**: firewall/service state, enabling insecure services, missing handlers for restarts.
  - **Compliance/best practices**: idempotency hints, `no_log` on sensitive tasks, package pinning, checksum/`validate` for config writes.

- **Best practice violations (impact)**:
  - **Secrets in plaintext**: risk of credential leakage via VCS and logs; use Ansible Vault/vars.
  - **No `no_log` on sensitive tasks**: secrets exposed in CI logs; set `no_log: true` per task.
  - **Using `shell` for idempotent tasks**: injection and drift risks; prefer modules like `user`, `copy`, `lineinfile`.

- **Remediation steps (how to fix)**:
  - **Move secrets to Vaulted vars**; reference via `{{ var }}` and mark tasks `no_log: true`.
  - **Replace `shell`/`command` with modules** (`user`, `file`, `copy`, `template`, `authorized_key`, package modules).
  - **Enforce secure file modes**: configs 0644, private keys 0600; set `owner`/`group`.
  - **Harden SSH** via `lineinfile` with `regexp` guards; reload service via handler.
  - **Constrain privilege**: add `become: true` only where needed; specify `become_user`.
  - **Add validation**: use `template` with `validate`, `copy` with `checksum`, and package pinning.

- **Remediations (examples)**:

```yaml
- name: Create DB user
  community.mysql.mysql_user:
    name: "{{ db_user }}"
    password: "{{ db_pass }}"  # stored in Vaulted vars
  no_log: true
```

```bash
ansible-vault encrypt group_vars/prod/vars.yml
```

```yaml
- name: Secure sshd_config
  become: true
  lineinfile:
    path: /etc/ssh/sshd_config
    regexp: '^PermitRootLogin'
    line: 'PermitRootLogin no'
    create: no
  notify: Restart ssh

- name: Ensure private key permissions
  file:
    path: /home/app/.ssh/id_rsa
    owner: app
    group: app
    mode: '0600'

- name: Install packages (idempotent)
  package:
    name:
      - openssh-server
      - ufw
    state: present

- name: Deploy config with validation
  template:
    src: app.ini.j2
    dest: /etc/app/app.ini
    mode: '0644'
    validate: '/usr/bin/appd --check-config %s'

handlers:
  - name: Restart ssh
    become: true
    service:
      name: ssh
      state: restarted
```




### Task 3 — Comparative Tool Analysis & Security Insights

#### Tool effectiveness matrix

```1:8:labs/lab6/analysis/tool-comparison.txt
=== Comprehensive Tool Comparison ===
Terraform Scanning Results:
  - tfsec: 53 findings
  - Checkov: 78 findings

Pulumi Scanning Results (KICS): 6 findings
Ansible Scanning Results (KICS): 9 findings
```

| Criterion | tfsec | Checkov | Terrascan | KICS |
|-----------|-------|---------|-----------|------|
| **Total Findings** | 53 (TF) | 78 (TF) | 22 (TF) | 6 Pulumi, 9 Ansible |
| **Scan Speed** | Fast | Medium | Medium | Medium |
| **False Positives** | Low | Medium | Medium | Medium |
| **Report Quality** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| **Ease of Use** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| **Documentation** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| **Platform Support** | Terraform | Multi‑framework | Multi‑framework | Pulumi, Ansible, more |
| **Output Formats** | JSON, text, SARIF | JSON, SARIF, CLI | JSON, human | JSON, HTML, SARIF |
| **CI/CD Integration** | Easy | Easy | Easy | Easy |
| **Unique Strengths** | Terraform depth, low noise | Broad policies & ecosystems | OPA/Rego and compliance mapping | First‑class Pulumi/Ansible queries |

#### Vulnerability category analysis

| Security Category | tfsec | Checkov | Terrascan | KICS (Pulumi) | KICS (Ansible) | Best Tool |
|------------------|-------|---------|-----------|---------------|----------------|----------|
| **Encryption Issues** | Strong | Strong | Moderate | Moderate | N/A | tfsec/Checkov |
| **Network Security** | Strong | Strong | Moderate | Moderate | N/A | tfsec/Checkov |
| **Secrets Management** | Moderate | Strong | Moderate | Moderate | Strong | Checkov/KICS (Ansible) |
| **IAM/Permissions** | Strong | Strong | Strong (policy) | Moderate | N/A | Checkov/Terrascan |
| **Access Control** | Strong | Strong | Moderate | Moderate | Moderate | tfsec/Checkov |
| **Compliance/Best Practices** | Moderate | Strong | Strong | Moderate | Moderate | Terrascan/Checkov |

Notes:
- tfsec excelled on SG/S3/RDS resource-level misconfigurations with actionable IDs.
- Checkov provided the largest breadth, including secrets and compliance-like checks.
- Terrascan’s OPA policies are well-suited for mapping to standards and custom governance.

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
    - group_vars/prod/vars.yml  # encrypted with Ansible Vault
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


