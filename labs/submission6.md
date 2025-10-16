
# Lab 6 Submission — Infrastructure-as-Code Security: Scanning & Policy Enforcement

## 1. Terraform Tool Comparison

**tfsec:** Detected 53 findings, excelling at identifying a wide range of Terraform-specific misconfigurations, including public S3 buckets, overly permissive security groups, and wildcard IAM policies. Fast scan speed, low false positives, and clear reporting.

**Checkov:** Found 4 findings. Focuses on policy-as-code, compliance, and multi-framework support. Detected fewer issues in this lab, but excels at identifying compliance violations and supports custom policies.

**Terrascan:** Reported 3 findings. OPA-based, strong for compliance mapping (PCI-DSS, HIPAA). Detected fewer issues, but useful for organizations with strict regulatory requirements.

**Summary:** tfsec provides the most comprehensive coverage for Terraform in this lab, while Checkov and Terrascan are valuable for compliance and multi-framework environments.

## 2. Pulumi Security Analysis (KICS)

KICS detected 6 findings in Pulumi YAML manifests:
- **HIGH severity:** 2
- **MEDIUM severity:** 2
- **INFO severity:** 2

Key issues included unencrypted DynamoDB tables, public S3 buckets, and open security groups. KICS’s Pulumi-specific query catalog effectively identified cloud misconfigurations unique to Pulumi’s YAML format.

## 3. Terraform vs. Pulumi — Security Issues Comparison

**Terraform (HCL):** Declarative, with strong tool support (tfsec, Checkov, Terrascan). Most tools excel at parsing HCL and finding misconfigurations, especially in AWS resources, IAM, and networking.

**Pulumi (YAML):** Programmatic, less tool coverage. KICS is the only open-source scanner with first-class Pulumi support. KICS found similar classes of issues (encryption, public access, secrets) but with fewer findings, likely due to less mature query coverage.

**Conclusion:** Terraform benefits from broader tool support and deeper query catalogs. Pulumi scanning is improving, but KICS is currently the best option for YAML-based Pulumi code.

## 4. KICS Pulumi Support Evaluation

KICS provides dedicated Pulumi queries for AWS, Azure, GCP, and Kubernetes. It auto-detects Pulumi YAML files and applies relevant checks. The query catalog covers encryption, access control, secrets management, and compliance. KICS is recommended for Pulumi scanning in CI/CD pipelines.

## 5. Critical Findings (Top 5)

1. **Public S3 Buckets (Terraform & Pulumi):** S3 buckets are world-readable. *Remediation:* Add `acl = "private"` and enable `server_side_encryption_configuration`.
2. **Overly Permissive Security Groups:** Security groups allow `0.0.0.0/0` ingress. *Remediation:* Restrict CIDR blocks to trusted IPs.
3. **Unencrypted RDS/DynamoDB Instances:** Databases lack encryption at rest. *Remediation:* Set `storage_encrypted = true` for RDS, enable `serverSideEncryption` for DynamoDB.
4. **Wildcard IAM Policies:** IAM roles grant `*` permissions. *Remediation:* Use least-privilege policies, specify required actions only.
5. **Hardcoded Secrets (Terraform, Pulumi, Ansible):** Credentials in plaintext. *Remediation:* Use AWS Secrets Manager, Ansible Vault, or environment variables.

## 6. Tool Strengths

- **tfsec:** Fast, Terraform-specific, low false positives, great for CI/CD.
- **Checkov:** Multi-framework, policy-as-code, compliance, custom rules.
- **Terrascan:** OPA-based, compliance mapping, regulatory focus.
- **KICS:** Unified scanning for Terraform, Pulumi, Ansible; strong Pulumi/Ansible support; broad query catalog.

---

## 7. Ansible Security Issues (KICS)

KICS detected 9 findings in Ansible playbooks:
- **HIGH severity:** 8
- **LOW severity:** 1

**Key Issues:**
1. Hardcoded passwords in playbooks
2. Missing `no_log` on sensitive tasks
3. Overly permissive file permissions
4. Insecure inventory configuration
5. Use of `shell` instead of proper modules

## 8. Best Practice Violations

1. **Hardcoded Secrets:** Secrets in playbooks and inventory. *Impact:* Exposes credentials, risk of leaks. *Remediation:* Use Ansible Vault.
2. **Missing `no_log`:** Sensitive operations not masked. *Impact:* Secrets exposed in logs. *Remediation:* Add `no_log: true` to sensitive tasks.
3. **File Permissions:** Files created with `0777`. *Impact:* Anyone can read/write, risk of privilege escalation. *Remediation:* Set permissions to `0644` or stricter.

## 9. KICS Ansible Queries Evaluation

KICS applies queries for secrets management, command execution, file permissions, authentication, and insecure configurations. It detects common misconfigurations and best practice violations, making it suitable for Ansible security in CI/CD.

## 10. Remediation Steps

- Encrypt secrets with Ansible Vault
- Add `no_log: true` to sensitive tasks
- Use proper file permissions
- Replace `shell` with Ansible modules
- Implement privilege escalation controls

---

## 11. Tool Comparison Matrix

| Criterion              | tfsec | Checkov | Terrascan | KICS (Pulumi/Ansible) |
|------------------------|-------|---------|-----------|-----------------------|
| Total Findings         | 53    | 4       | 3         | 6 (Pulumi), 9 (Ansible) |
| Scan Speed             | Fast  | Medium  | Medium    | Medium                |
| False Positives        | Low   | Medium  | Medium    | Medium                |
| Report Quality         | ⭐⭐⭐⭐  | ⭐⭐⭐    | ⭐⭐⭐      | ⭐⭐⭐⭐                  |
| Ease of Use            | ⭐⭐⭐⭐  | ⭐⭐⭐    | ⭐⭐⭐      | ⭐⭐⭐⭐                  |
| Documentation          | ⭐⭐⭐⭐  | ⭐⭐⭐⭐   | ⭐⭐⭐      | ⭐⭐⭐⭐                  |
| Platform Support       | Terraform | Multi | Multi     | Multi                 |
| Output Formats         | JSON, text | JSON, text | JSON, text | JSON, HTML, text |
| CI/CD Integration      | Easy  | Easy    | Medium    | Easy                  |
| Unique Strengths       | Terraform-specific | Policy-as-code | Compliance | Pulumi/Ansible support |

## 12. Category Analysis

| Security Category      | tfsec | Checkov | Terrascan | KICS (Pulumi) | KICS (Ansible) | Best Tool |
|-----------------------|-------|---------|-----------|---------------|----------------|-----------|
| Encryption Issues      | ✅    | ✅      | ✅        | ✅            | ❌            | tfsec/KICS|
| Network Security      | ✅    | ✅      | ✅        | ✅            | ✅            | tfsec/KICS|
| Secrets Management    | ✅    | ✅      | ✅        | ✅            | ✅            | KICS      |
| IAM/Permissions       | ✅    | ✅      | ✅        | ✅            | ❌            | tfsec     |
| Access Control        | ✅    | ✅      | ✅        | ✅            | ✅            | tfsec/KICS|
| Compliance/Best Practices | ✅ | ✅      | ✅        | ✅            | ✅            | Checkov   |

## 13. Top 5 Critical Findings (with Remediation)

1. **Public S3 Buckets:** Set `acl = "private"`, enable encryption.
2. **Open Security Groups:** Restrict ingress CIDR blocks.
3. **Unencrypted Databases:** Enable encryption at rest.
4. **Wildcard IAM Policies:** Use least-privilege.
5. **Hardcoded Secrets:** Use Vaults/Secrets Manager.

## 14. Tool Selection Guide

- **tfsec:** Fast, reliable for Terraform. Use in CI/CD for quick feedback.
- **Checkov:** Best for compliance, policy-as-code, multi-framework.
- **Terrascan:** Use for regulatory compliance mapping.
- **KICS:** Best for Pulumi and Ansible, unified scanning, broad query catalog.

## 15. Lessons Learned

- Multiple tools are needed for full IaC coverage.
- False positives vary; tfsec is most reliable for Terraform.
- KICS is essential for Pulumi and Ansible.
- Compliance tools (Checkov, Terrascan) are valuable for regulated environments.

## 16. CI/CD Integration Strategy

- Integrate tfsec, Checkov, and KICS in pipeline stages.
- Use pre-commit hooks for early detection.
- Run all tools on PRs, block merges on critical findings.
- Regularly update tool versions and rule sets.

## 17. Justification

Using a combination of tfsec, Checkov, Terrascan, and KICS provides comprehensive coverage across Terraform, Pulumi, and Ansible. Each tool excels in different areas, and together they ensure robust IaC security for modern DevSecOps pipelines.
