## Task 1
### Terraform Tool Comparison - Effectiveness of tfsec vs. Checkov vs. Terrascan
Terraform Scanning Results:
  - tfsec: 53 findings
  - Checkov: 78 findings
  - Terrascan: 22 findings
### Pulumi Security Analysis - Findings from KICS on Pulumi code
  - 6 findings


Terraform vs. Pulumi - Compare security issues between declarative HCL and programmatic YAML approaches

  - Terraform’s declarative style simplifies security management but may expose sensitive data. Pulumi’s programmatic approach offers flexibility and better secret handling but increases complexity and potential vulnerabilities.


KICS Pulumi Support - Evaluate KICS's Pulumi-specific query catalog


Critical Findings - At least 5 significant security issues

- Misconfigured S3 buckets can leak private information to the entire internet or allow unauthorized data tampering / deletion
- Security Groups - Unrestricted Specific Ports - Postgres SQL
- DynamoDB Table Not Encrypted
- Passwords And Secrets - Generic Password

Tool Strengths - What each tool excels at detecting

- tfsec:	Excels at detecting misconfigurations in Terraform scripts, including insecure storage, IAM issues, and open ports.
- Checkov:	Specializes in identifying a wide range of infrastructure security vulnerabilities, including those related to Terraform, CloudFormation, Kubernetes, and Docker configurations, ensuring compliance with best practices.
- Terrascan:	Focuses on detecting violations against compliance standards and policies, as well as identifying security issues related to infrastructure-as-code across various platforms, leveraging OPA for complex policy evaluations.

## Task 2


Ansible Security Issues - Key security problems identified by KICS

- Passwords And Secrets - Generic Password (6 times)
- Passwords And Secrets - Password in URL (2 timess)

Best Practice Violations - Explain at least 3 violations and their security impact

 - Passwords And Secrets - Generic Password \
Attackers exploit these to gain control of systems.

 - Password in URL Violation \
Violation: Including passwords or sensitive credentials directly in URLs. \
URLs can be logged or shared, possibly disclosing sensitive information.



KICS particularly focusing on areas like secrets management and supply chain risks. 

Remediation Steps:
1. Use the outputs from KICS to locate all instances where secrets are hard-coded.
2. Utilize environment variables or secret management solutions


## Task 3.



| Criterion           | tfsec                 | Checkov               | Terrascan            | KICS                   |
|---------------------|-----------------------|-----------------------|----------------------|------------------------|
| **Total Findings**   | 53                    | 78                    | 22                   | 15 (Pulumi + Ansible)  |
| **False Positives**  | Low                   | Medium                | Medium               | Low                    |
| **Scan Speed**       | Fast                  | Slow                  | Medium               | Medium                 |
| **Report Quality**    | ⭐⭐⭐⭐                 | ⭐⭐⭐⭐⭐                | ⭐⭐⭐                 | ⭐⭐⭐                   |
| **Ease of Use**      | ⭐⭐⭐⭐                 | ⭐⭐⭐                  | ⭐⭐⭐⭐                | ⭐⭐⭐⭐                  |
| **Documentation**     | ⭐⭐⭐⭐                 | ⭐⭐⭐⭐⭐                | ⭐⭐⭐                 | ⭐⭐⭐                   |
| **Platform Support**  | Terraform only        | Multiple              | Multiple             | Multiple               |
| **Output Formats**    | JSON, text, SARIF, etc| JSON, text, SARIF, etc| JSON, text           | JSON, text, SARIF      |
| **CI/CD Integration**  | Easy                  | Medium                | Medium               | Easy                   |
| **Unique Strengths**  | Lightweight, fast     | Comprehensive checks   | Strong policies      | Supports additional tools|


| **Security Category**        | **tfsec** | **Checkov** | **Terrascan** | **KICS (Pulumi)** | **KICS (Ansible)** | **Best Tool** |
|-------------------------------|-----------:|-------------:|---------------:|-------------------:|-------------------:|----------------|
| **Encryption Issues**         | 8 | 9 | 3 | 1 | 0 | Checkov |
| **Network Security**          | 9 | 17 | 6 | 0 | 0 | Checkov |
| **Secrets Management**        | 0 | 1 | 1 | 1 | 8 | KICS (Ansible) |
| **IAM / Permissions**         | 11 | 21 | 2 | 0 | 0 | Checkov |
| **Access Control**            | 10 | 10 | 3 | 1 | 0 | tfsec/Checkov |
| **Compliance / Best Practices** | 15 | 20 | 7 | 3 | 1 | Checkov |
