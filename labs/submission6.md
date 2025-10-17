# Lab 6 - Infrastructure-as-Code Security: Scanning & Policy Enforcement

## Task 1 - Terraform & Pulumi Security Scanning

### Terraform Tool Comparison - tfsec vs. Checkov vs. Terrascan

| Tool  | Findings | 
|-------|----------|
| **tfsec**     | 53 | 
| **Checkov**   | 78 |
| **Terrascan** | 22 |      

### Coverage and rules

 Checkov: The broadest coverage, including cloud, CI/CD, and container policies.
 tfsec: Focused on Terraform, providing clear recommendations.
 Terrascan: Fewer findings, but a strong emphasis on compliance with standards and policies.

### Signal vs noise

 Checkov: Many false positives, requiring suppression settings.
 tfsec: Consolidates output, good for small projects.
 Terrascan: Fewer alerts, but may miss out specific rules.

### Usability

 tfsec: Simple CLI, readable output.
 Checkov: Flexible format, easy to integrate into CI.
 Terrascan: Good for automation, strict policy model.

### Output

 Checkov is the leader in coverage.
 tfsec is optimal for quick triage.
 Terrascan is useful for meeting security requirements.

### Pulumi Security Analysis - KICS Results

| Metric             | Count |
|--------------------|------:|
| **Total findings** | **6** |
| - HIGH             |     2 |
| - MEDIUM           |     2 |
| - INFO             |     2 |


#### Observations

- The main findings are weak encryption, open networks, and IAM/resource leaks.  
- A smaller number of issues are related to limited use of Pulumi and differences in syntax.  
- KICS queries cover common AWS/Azure/GCP errors well, and reports can be exported and shared with the team.

---

### Terraform vs. Pulumi - Security Themes

- Terraform uses a declarative style in HCL, where resources and modules are explicitly described. Pulumi, on the other hand, uses a programmable configuration that can be generated into YAML or manifests.
- In terms of static analysis, Terraform has a high level of analyzability due to its mature scanners and extensive rule sets. Pulumi is developing this aspect, with KICS already covering many key cloud checks.
- Typical errors in Terraform include public access to services, lack of encryption, excessive IAM permissions, open security groups, and insecure S3/Blob settings. Pulumi has similar issues, but adds the risk of conditional resource generation, especially if the default values are not secure.
- In terms of triage convenience, Terraform wins with its extensive tooling and IDE integrations. Pulumi is also convenient with KICS, but has fewer compatible tools.
- Conclusion: Both approaches can be securely protected. Terraform wins with a mature tooling ecosystem, while Pulumi requires special attention to secure defaults and validation of generated manifests.
---

### KICS Pulumi Support - Evaluation

- KICS supports Pulumi YAML and covers key risks in AWS, Azure, and GCP.  
- Checks include encryption, public access, network settings, and IAM.  
- The query catalog is actively developed, and results can be easily exported in JSON/HTML.  
- Suitable for basic hardening and reporting in CI/CD.

---

### Critical Findings (Top 5+ Themes)

1. Open access to the database. The Security Group allows incoming traffic from 0.0.0.0/0 to sensitive ports. Limit CIDR and ports (AVD-AWS-0107).
2. Full egress access. Several Security Groups allow outgoing traffic at 0.0.0.0/0. Specify acceptable CIDR ranges (AVD-AWS-0104).
3. An unencrypted database. The RDS instance stores data without encryption. Enable storage encryption (AVD-AWS-0082, CKV_AWS_16).
4. Public access to the S3 bucket. The ACL is enabled and there is no blocking of public access. Configure block-public-access (AC_AWS_0210/0496).
5. Lack of DATABASE backup. The RDS instance does not save backups. Set backup_retention_period > 0 (AC_AWS_0052, CKV_AWS_129).
6. Public RDS instance. The database is accessible from the outside via a public network. Switch to a private subnet (CKV_AWS_17).
7. IAM with mask rights. Wildcard (*) actions and resources are used without conditions. Restrict rights and add condition keys.
---

### Tool Strengths - What Each Excels At

**tfsec**

 * Specializes in Terraform, provides concise and understandable recommendations.  
 * A good balance between coverage and the number of false positives; easily implemented in local development and PR checks.

**Checkov**

 * The most extensive policy catalog, including deep cloud and Kubernetes support.  
 * Great for large-scale projects: supports annotations, exclusions, and integration with CI/CD.

**Terrascan**

 * It is focused on the "policy as code" approach, uses OPA/Rego.  
 * It provides concise and targeted results, convenient for automatic pipeline checks.

**KICS (Pulumi)**

 * Full-fledged Pulumi support with a clear classification of risks.  
 * It is convenient as the main static scanner for Pulumi; HTML reports are suitable for reporting to stakeholders.

---

## Task 2 - Ansible Security Scanning with KICS

**Totals:** 9 findings • **HIGH:** 8 • **MEDIUM:** 0 • **LOW:** 1

### Ansible Security Issues (Key Problems)

1. Unsafe use of shell and command. The lack of creates/removes and input filtering can lead to command injection and idempotence violations.
2. Files with write permissions for everyone (0777). Setting such rights through the file or copy modules creates a risk of privilege escalation and lateral movement.
3. Non-fixed versions of packages. Using apt, yum, or pip without specifying versions can lead to dependency drift and installation of vulnerable components.
4. Unsafe service configuration. Running services without enabling TLS or secure configurations can open access to insecure daemons.
5. Open secrets in variables and templates. Storing passwords and keys in the clear leads to their leakage through repositories, CI logs, or artifacts.

### Best Practice Violations (Examples & Impact)


 - Lack of become: false in normal tasks or excessive use of privileges. Increases the potential damage caused by errors in the playbook.
 - Using shell/command instead of specialized modules. The risk of command injection and unstable behavior during restart.
 - Weak access rights (e.g. 0644) for private keys or configurations with credentials. Unauthorized access by other users is possible.

### KICS Ansible Queries — What It Checks

 - Handling secrets in variables and templates.  
 - Open services and network settings (for example, running without TLS or without firewall settings).  
 - Hygiene of sources and packages (non-fixed versions, insecure protocols, lack of GPG signature).  
 - Using risky modules and templates (for example, shell without checks, input without validation).  
 - Insecure access rights and owners of files/directories.

### Remediation Steps (Targeted)

1. Secret Management. Use Ansible Vault, environment variables, or external storage. Don't keep secrets in the clear.
2. Secure modules and commands. Prefer user, package, systemd, etc. instead of shell. When using shell, add creates, unless, etc.
3. Version and source control. Fix package versions, check sources, and avoid state: latest.
4. Minimizing privileges. By default, become: false. Enable become: true only if necessary.
5. Strengthening configurations. Set minimum permissions (0600 for secrets), configure TLS, logging, and firewall.
---

## Task 3 - Comparative Tool Analysis & Security Insights

### Tool Comparison Matrix

| Criterion             | tfsec                          | Checkov                         | Terrascan               | KICS                                              |
| --------------------- | ------------------------------ | ------------------------------- | ----------------------- | ------------------------------------------------- |
| **Total Findings**    | 53                             | 78                              | 22                      | 6 (Pulumi) + 9 (Ansible)                          |
| **Scan Speed**        | Fast                           | Medium                          | Medium                  | Fast                                              |
| **False Positives**   | Low–Medium                     | Medium–High                     | Low–Medium              | Medium                                            |
| **Report Quality**    | ⭐⭐⭐                            | ⭐⭐⭐⭐                            | ⭐⭐                      | ⭐⭐⭐ (JSON/HTML)                                   |
| **Ease of Use**       | ⭐⭐⭐⭐                           | ⭐⭐⭐                             | ⭐⭐⭐                     | ⭐⭐⭐                                               |
| **Documentation**     | ⭐⭐⭐                            | ⭐⭐⭐⭐                            | ⭐⭐⭐                     | ⭐⭐⭐                                               |
| **Platform Support**  | Terraform                      | Multiple (Terraform, K8s, etc.) | Multiple                | Multiple (Ansible, Terraform*, K8s, Docker, etc.) |
| **Output Formats**    | JSON, text, SARIF              | JSON, SARIF, JUnit, CLI         | JSON, human             | JSON, HTML, CLI                                   |
| **CI/CD Integration** | Easy                           | Easy                            | Medium                  | Easy                                              |
| **Unique Strengths**  | Dev-friendly, concise guidance | Broadest rules & guardrails     | Policy/governance focus | First-class Ansible & Pulumi coverage             |



### Vulnerability Category Analysis

| Security Category             | tfsec      | Checkov         | Terrascan | KICS (Pulumi) | KICS (Ansible) | **Best Tool**           |
| ----------------------------- | ---------- | --------------- | --------- | ------------- | -------------- | ----------------------- |
| **Encryption Issues**         | Strong     | **Very strong** | Moderate  | Strong        | N/A            | **Checkov**             |
| **Network Security**          | **Strong** | Strong          | Moderate  | Moderate      | Moderate       | **tfsec / Checkov**     |
| **Secrets Management**        | Moderate   | **Strong**      | Basic     | Strong        | **Strong**     | **Checkov / KICS**      |
| **IAM/Permissions**           | Strong     | **Very strong** | Moderate  | Moderate      | Moderate       | **Checkov**             |
| **Access Control**            | Strong     | **Strong**      | Moderate  | Moderate      | Strong         | **Checkov / tfsec**     |
| **Compliance/Best Practices** | Moderate   | **Very strong** | Strong    | Moderate      | Strong         | **Checkov / Terrascan** |

**Notes:**



### Top 5 Critical Findings (Deep Dive + Fixes)
1. **Open SSH access (0.0.0.0/0)**  
   Without restrictions on IP addresses, the SSH port is accessible from anywhere on the Internet, which creates a risk of unauthorized access. It is recommended to restrict access to trusted networks (for example, an office or VPN).
2. **Public access to the object storage (S3)**
Failure to block public access to buckets can lead to data leakage. It is necessary to include policies prohibiting public ACLs and policies.
3. **Unencrypted volumes and storage**
   Using EBS or other storage without encryption jeopardizes data privacy. You should enable encryption and use KMS keys.
4. **Masked IAM Policies (*)**
Applying wildcard access to actions and resources without conditions increases the risk of privilege escalation. It is recommended to limit actions and resources by adding conditions (for example, MFA).
5. **Secrets in the clear in the code**
   Storing passwords and keys directly in configuration files can lead to their leakage through repositories or CI. You should use Ansible Vault, Secrets Manager, or environment variables.


### Tool Selection Guide

1. **Quick PR and CI/CD verification**
   Use tfsec (and/or Checkov) with SARIF annotations for fast and accurate feedback in Terraform projects.
2. **Organizational policies and compliance**  
   Use Checkov as your main tool — it covers Terraform, Kubernetes, Docker and other formats.
3. **Policies as code and centralized management** 
   Use Terrascan with Rego/OPA for strict compliance control (PCI-DSS, HIPAA, CIS).
4. **Projects on Pulumi and Ansible** 
   Choose KICS as your main scanner, complementing it with specialized linters like ansible-lint.

### Lessons Learned

1. **No single tool covers everything.**  
   Each scanner has its own strengths, especially outside of Terraform. To ensure full visibility, it is important to combine several tools.
2. **Checkov vs. tfsec: Coverage vs. accuracy**  
   Checkov finds more problems thanks to a wide catalog of rules, but requires adjustments to reduce noise. tfsec provides fewer false positives and is faster for early validation.
3. **Context is important when comparing results.**  
   The number of finds depends on the intersection of rules and deduplication. The comparison should be based on the severity of the vulnerabilities and the importance of the affected resources.
4. **Overlap is a plus, not a minus.**  
   Matching findings confirm real problems, while unique findings reveal gaps between tools. This enhances defense based on the defense-in-depth principle.


### CI/CD Integration Strategy (Practical)

1. **Matrix assembly along the Terraform, Pulumi and Ansible paths**
   Configure CI so that scanners run on each type of infrastructure code independently.
2. **Parallel launch of scanners**  
   Use tfsec, Checkov, Terrascan, and KICS simultaneously to speed up analysis and cross-validation.
3. **Pre-commit and PR protection**  
   Run tfsec and Checkov locally before committing, and in the pull request — complete scans of all tools.
4. **Build Failure Policies**  
   Abort the build when vulnerabilities of HIGH or higher level are detected; warn at MEDIUM; publish reports in any case.
5. **Publication and annotation of reports**  
   Download JSON/HTML reports, convert them to SARIF for display directly in the pull request (for example, via GitHub Code Scanning).
6. **Basic policies and exclusions**  
   Keep baseline files and annotations of exceptions with justification in the repository; review them quarterly.
7. **Night and post-deployment scans**  
   Run Terrascan and other tools on the main branch on a schedule to detect drift and violations after releases.

---