# Lab 6 — Infrastructure-as-Code Security: Scanning & Policy Enforcement

## Task 1 — Terraform & Pulumi Security Scanning

### Terraform Tool Comparison

- **tfsec**: Found 21 issues in Terraform code, good at detecting misconfigured S3 buckets, security groups, and IAM policies.
- **Checkov**: Found 29 failed checks, strong in identifying hardcoded secrets, privilege escalation, and compliance misconfigurations.
- **Terrascan**: Found 8 violated policies, effective for basic policy enforcement and standard Terraform best practices.

### Pulumi Security Analysis

- **KICS Pulumi scan**: 0 vulnerabilities found in Pulumi YAML (`Pulumi-vulnerable.yaml`) and Python code scan reported, likely due to limited YAML content in test setup.
- **Severity**: HIGH: 0, MEDIUM: 0, LOW: 0, TOTAL: 0

### Terraform vs. Pulumi

- Terraform (HCL) scanning detected 21–29 security issues across multiple tools.
- Pulumi (YAML/Python) scanning with KICS found 0 issues in YAML and 2 in Ansible examples.
- Declarative HCL allows more static analysis coverage, while programmatic Pulumi can require dynamic or language-aware scanning.

### KICS Pulumi Support

- KICS supports Pulumi YAML manifests with a dedicated query catalog.
- It can detect misconfigured cloud resources, open S3 buckets, and insecure security groups.
- Coverage depends on resource definitions; minimal YAML may yield zero findings.

### Critical Findings

1. Public S3 buckets with `acl: public-read` (tfsec, Checkov)
2. Overly permissive security groups allowing SSH from 0.0.0.0/0 (tfsec, Checkov)
3. Wildcard IAM permissions granting all actions (Checkov)
4. Unencrypted publicly accessible RDS instances (tfsec)
5. Hardcoded database passwords in Terraform variables (Checkov)

### Tool Strengths

- **tfsec**: Cloud misconfigurations, insecure S3, open security groups.
- **Checkov**: Hardcoded secrets, IAM privilege escalation, compliance misconfigurations.
- **Terrascan**: Policy violations and Terraform best practices.
- **KICS**: Pulumi YAML manifest vulnerabilities, supports multiple IaC frameworks including Ansible and Pulumi.

### Screenshots
<img width="959" height="420" alt="image" src="https://github.com/user-attachments/assets/5ad13395-d1dd-4b7b-9a30-5a874cd52dfa" />
<img width="959" height="455" alt="image" src="https://github.com/user-attachments/assets/3250327c-a0bf-40ca-8bcf-4f51befdca44" />

## Task 2 — Ansible Security Scanning with KICS

- Hardcoded secrets in inventory.ini (ansible_password exposed)
- Hardcoded database password in deploy.yml

### Best Practice Violations

1. **Hardcoded passwords** — risk of credential leaks if repository is public.
2. **Exposed secrets in playbooks** — sensitive data could appear in logs or version control.
3. **Lack of secure variable handling** — does not use Ansible Vault or environment variables, increasing attack surface.

### KICS Ansible Queries

- Detects passwords and secrets in playbooks and inventory
- Checks for command execution vulnerabilities
- Verifies file permissions and access control
- Authentication and access misconfigurations
- Identifies insecure configurations and best practice violations

### Remediation Steps

- Remove hardcoded passwords; store secrets securely with Ansible Vault.
- Avoid putting sensitive variables directly in playbooks or inventory files.
- Use environment variables or encrypted files for sensitive data.
- Apply proper file permissions to inventory and playbooks to prevent unauthorized access.

### Ansible Security Issues

<img width="959" height="978" alt="image" src="https://github.com/user-attachments/assets/22a4e91f-de76-4a5b-8a07-1ecec1defb6d" />

## Task 3 — Comparative Tool Analysis & Security Insights

### Create Comprehensive Tool Comparison

#### Terraform Scanning Results
- tfsec: 21 findings
- Checkov: 29 findings
- Terrascan: 8 findings

#### Pulumi Scanning Results (KICS)
- Total findings: 2

#### Ansible Scanning Results (KICS)
- Total findings: 2

#### Tool Effectiveness Matrix

| Criterion           | tfsec       | Checkov    | Terrascan  | KICS (Pulumi + Ansible) |
|--------------------|------------|-----------|-----------|------------------------|
| Total Findings      | 21         | 29        | 8         | 4                      |
| Scan Speed          | Fast       | Medium    | Medium    | Medium                 |
| False Positives     | Low        | Medium    | Medium    | Low/Medium             |
| Report Quality      | ⭐⭐⭐⭐       | ⭐⭐⭐⭐⭐     | ⭐⭐⭐⭐      | ⭐⭐⭐⭐                   |
| Ease of Use         | ⭐⭐⭐⭐       | ⭐⭐⭐⭐      | ⭐⭐⭐       | ⭐⭐⭐⭐                   |
| Documentation       | ⭐⭐⭐⭐       | ⭐⭐⭐⭐⭐     | ⭐⭐⭐       | ⭐⭐⭐⭐                   |
| Platform Support    | Terraform only | Multiple | Multiple | Multiple               |
| Output Formats      | JSON, text, SARIF | JSON, text, SARIF | JSON, text | JSON, HTML, text |
| CI/CD Integration   | Easy       | Easy      | Medium    | Medium                 |
| Unique Strengths    | Quick misconfig detection | Extensive policy coverage | Compliance-focused policies | Multi-platform IaC scanning |

### Vulnerability Category Analysis

| Security Category          | tfsec | Checkov | Terrascan | KICS (Pulumi) | KICS (Ansible) | Best Tool |
|----------------------------|-------|---------|-----------|---------------|----------------|-----------|
| Encryption Issues          | 2     | 2       | 1         | 0             | N/A            | Checkov  |
| Network Security           | 3     | 2       | 1         | 0             | 0              | tfsec    |
| Secrets Management         | 0     | 1       | 0         | 1             | 2              | KICS Ansible |
| IAM/Permissions            | 4     | 5       | 2         | 0             | 0              | Checkov  |
| Access Control             | 3     | 2       | 2         | 0             | 0              | tfsec    |
| Compliance/Best Practices  | 2     | 2       | 2         | 0             | 0              | Terrascan |

#### Top 5 Critical Findings

| ID / Query       | Tool          | Description                                              | File |
|-----------------|---------------|----------------------------------------------------------|------|
| AVD-AWS-0057     | tfsec         | IAM policy document uses wildcarded action '*'           | N/A  |
| AVD-AWS-0057     | tfsec         | IAM policy document uses sensitive action '*' on wildcarded resource '*' | N/A |
| AVD-AWS-0180     | tfsec         | Instance has Public Access enabled                        | N/A  |
| AVD-AWS-0080     | tfsec         | Instance does not have storage encryption enabled        | N/A  |
| AVD-AWS-0086     | tfsec         | No public access block so not blocking public ACLs       | N/A  |

*(Checkov, Terrascan, KICS Pulumi, and KICS Ansible detailed findings are included in the CSV and JSON reports.)*

#### Tool Selection Guide
- Quick misconfig scan: tfsec  
- Comprehensive policy coverage: Checkov  
- Compliance-focused scanning: Terrascan  
- Multi-platform IaC scanning: KICS  

#### Lessons Learned
- Terraform HCL has more detectable misconfigurations; Pulumi reduces boilerplate errors.  
- False positives exist in all tools; cross-tool comparison recommended.  
- KICS is flexible but fewer queries for Pulumi compared to Terraform-focused tools.  

#### CI/CD Integration Strategy
- Multi-stage pipeline:
  1. Pre-commit: tfsec or KICS lint
  2. CI pipeline: Checkov/Terrascan for Terraform, KICS for Pulumi/Ansible
  3. Post-deploy: Optional runtime compliance scans

#### Justification
- Using multiple tools reduces blind spots.  
- tfsec/Checkov/Terrascan cover Terraform comprehensively.  
- KICS supports multi-IaC scenarios.  
- Ansible-specific risks are best handled by KICS Ansible queries.
