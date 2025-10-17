# Terraform Tool Comparison

1) Total issues found:


    **tfsec.** 18 files detected

    **Checkov**. 12 files detected

    **Terrascan**. 22 filed detected

2) Issues severity:

    **tfsec.** 4 Critical, 2 High, 1 Medium, 3+ Low

    **Checkov**. Severity missing

    **Terrascan**. 14 High, 8 Medium

3) Scan scope:

    **tfsec.** Terraform only

    **Checkov**. Terraform, CloudFormation, Kubernetes, ARM, Helm

    **Terrascan**. Terraform, Kubernetes, CloudFormation

4) Performance

    **tfsec.** Very fast, minimal dependencies

    **Checkov**. Moderate

    **Terrascan**. Slightly slower than tfsec but faster than Checkov

5) Detection quality:

    **tfsec.** detects specific egress/ingress rules with line precision, generally shows poor results

    **Checkov.** most compliance-ready, most detailed IAM security scanning

    **Terrascan.** most complete with the most comprehensive coverage, and most AWS-specific operational resilience

## Pulumi Security Analysis - Key Findings

1) **DynamoDB Table Not Encrypted** (HIGH). `serverSideEncryption` missing – unencrypted data at rest 

2) **Passwords and Secrets in Code** (HIGH).
Hardcoded secret key found in Pulumi YAML

3) **EC2 Instance Monitoring Disabled** (MEDIUM). Missing `monitoring=true`, limits visibility

4) **RDS Publicly Accessible** (MEDIUM). RDS instance allows public access

5) **DynamoDB PITR Disabled** (INFO). `pointInTimeRecovery` disabled — reduced recoverability

6) **EC2 Not EBS Optimized** (INFO). Missing `ebsOptimized=true`, potential performance issue

## Terraform vs. Pulumi

1) **Terraform (HCL)** offers stronger static security guarantees — safer defaults, predictable scanning, mature tooling (tfsec, Checkov, Terrascan)

2) **Pulumi (Programmatic IaC)** offers developer agility, but increases security risk: 
    ```
    Dynamic code can bypass policy checks.

    Secrets and credentials are often embedded in source.

    Requires discipline and runtime scanning
    ````

Terraform’s declarative HCL is easier to statically validate and harder to abuse programmatically. Pulumi’s flexibility increases developer productivity — but also increases potential attack surface via code execution and dynamic secrets

## KICS Pulumi Support

1) **Baseline misconfiguration coverage**: Good — covers encryption, public exposure, best practices

2) **Secret detection**: Strong — includes generic password queries

3) **Provider / resource breadth**: Medium — common resources likely well supported; exotic ones less so

4) **Dynamic logic / code support**: Weak — can’t analyze runtime-generated logic

5) Documentation & discoverability: Weak  — lack of dedicated Pulumi query docs

KICS’s Pulumi support is functional and valuable for many common misconfigurations, but not (yet) a full replacement for deeper policy checks or runtime-aware security analysis in Pulumi

## Critical Findings

1) Publicly Accessible Databases (RDS / DB Instances). [Checkov, Terrascan, KICS] - High. RDS instances have `publicly_accessible = true`

2) Unencrypted Data at Rest (RDS / DynamoDB). [tfsec, Terrascan, KICS] - High. Missing `storage_encrypted` or `serverSideEncryption` attributes

3) Open Security Groups (0.0.0.0/0). [tfsec, Terrascan] - Critical. Ingress/egress open to all IPs or ports

4) Hardcoded Secrets or Passwords in Source Code. [KICS] - Critical. Static secrets detected in Pulumi YAML

5) IAM Policy Wildcards (* Actions or Resources). [fsec, Terrascan, Checkov] - High. IAM permissions too broad - Enables privilege escalation or resource deletion

## Tool Strength

1) **tfsec**. Terraform-native static analysis with high accuracy and low false positives. Detects granular misconfigurations at resource level

2) **Checkov**. Broad compliance coverage — integrates CIS, NIST, GDPR, SOC2 policies. Great for multi-IaC and compliance enforcement

3) **Comprehensive AWS detection**. Covers ports, backups, IAM, encryption, and resilience. Uses OPA/Rego for extensibility

4) **Secret detection + Pulumi YAML scanning** Works across IaC types including Pulumi, Docker, and Kubernetes. Provides fast scanning

# Ansible Security Issues

1) Hardcoded secrets and passwords.
Files: inventory.ini, configure.yml, deploy.yml.

2) Passwords embedded in URLs (deploy.yml)

3) Unpinned package installs (Ansible apt with latest) (deploy.yml)

4) Multiple redundant hardcoded credentials across inventory and playbooks

5) Unpinned package version. This can become security issue during upgrades or rollback events

## Best Practice Violations - Explanation

1) Hardcoded secrets and passwords: secrets in plaintext lead to credential theft if source is exposed. They are often long-lived and can be reused by attackers to access systems

2) Passwords embedded in URLs: URLs are often logged, stored in CI variables, or shown in error messages — making passwords trivially discoverable

3) Unpinned package installs: installing latest can pull in unexpectedly updated packages (malicious or broken), introducing supply-chain risk

## KICS Ansible Queries

We conclude that KICS definetly provides

1) **Secret Management**: generic password detection, password in URL detection, secret-like pattern matching

2) **Package Safety**: Detects apt/yum usage with state: latest or missing version pins

3) **Best Practices & Observability**: Detects missing monitoring flags and other operational deficiencies (in other IaC contexts)

**KICS** provides a useful, broad set of pattern-based checks that quickly surface glaring issues

## Remediation Steps

1) `Credentials in URLs`. Remove credentials from URLs and instead use dedicated variables or secret lookups

2) `Remove secrets from source control immediately`. Search the repo and replace any plaintext secrets. Also Use external secret managers

3) `Rotate any secrets that were committed`. Assume compromise for secrets that were in repo history or backups

4) `Package version pinning`. Avoid state: latest in production playbooks. Pin packages to explicit versions when possible

# Tool Effectiveness Matrix

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

## Vulnerability Category Analysis

| Category | tfsec | Checkov | Terrascan | KICS (Pulumi) | KICS (Ansible) | Best tool |
| --- | --- | --- | --- | --- | --- | --- |
| **Network (SG open, 0.0.0.0/0)** | Yes (detailed) | Yes | Yes (port-level) | Yes (if in manifest) | N/A | tfsec / Terrascan |
| **Encryption (RDS/DynamoDB/S3)** | Yes | Yes | Yes | Yes | N/A | Terrascan / Checkov |
| **IAM & privilege** | Yes | Yes | Yes | Partial | Partial | Checkov / tfsec |
| **Secrets in code** | No | No | No | Yes (Pulumi YAML) | Yes (Ansible) | KICS |
| **Backup/Resilience** | Yes | Yes | Yes | Yes | Yes | Terrascan / Checkov |
| **Compliance benchmarks (CIS/NIST)** | No | Yes | Yes | Partial | Partial | Checkov / Terrascan |

## Top 5 Critical Findings With Remediation Examples

1) Publicly accessible RDS / DB instances `(publicly_accessible = true)`. Ensure DB provisioning modules set `publicly_accessible: false` or the cloud provider console is configured to block public access

2) Open Security Groups `(Ingress/Egress 0.0.0.0/0)`. Use least-privilege network rules, security group references instead of wide CIDRs

3) Unencrypted resources at rest (RDS `storage_encrypted=false`, DynamoDB missing `serverSideEncryption`). Make storages encrypted or enable server-side encryption

4) Hardcoded secrets in source (API keys, DB passwords). Move secrets to remote state or use variables from secret stores (e.g., AWS SSM)

5) Overly permissive IAM policies (`"Action": ["*"]` or `"Resource":"*"`). Apply least privilege; use IAM roles for services; require review & approval for any policy that expands scope

## Tool Strengths — what each tool excels at detecting

**tfsec**:

    1) Highly accurate Terraform-specific checks.

    2) Low noise, developer-friendly output with precise file+line reporting.

    3) Great for fast developer pre-commit/PR checks.

**Checkov**:

    1) Excellent for compliance and policy-as-code.

    2) Large set of built-in benchmarks and multi-IaC support.

    3) Great for CI/CD gates and regulatory requirements.

**Terrascan**:

    1) Strong AWS-specific rule coverage.

    2) Strong mapping to compliance frameworks, good for enterprise baselines.

**KICS**:

    1) Supports Pulumi YAML and Ansible natively; unique strength in secret detection.

    2) Fast scanning, easy to run in CI, and good multi-language IaC coverage.

    Combined approach recommendation: use tfsec for developer feedback, Checkov/Terrascan for compliance and pipeline enforcement, and KICS for Pulumi/Ansible + secrets scanning. Combine tools in layered pipeline.

## Lessons learned & limitations

**No single tool catches everything**. Use layered detection: developer tooling (fast + low noise) + CI tools (compliance, deeper checks)

**Dynamic IaC (Pulumi)** static scanning (Pulumi YAML) helps, but code-level checks are required

**Secrets** in code require specialized scanning - standard Terraform scanners may miss secrets embedded in other files.

**False positives** occur with some compliance checks

## Tool Selection Guide & Recommendations

1) Developer pre-commit & PR checks (fast feedback): tfsec + KICS (for Pulumi/Ansible)

2) Enterprise policy & compliance gate: Checkov (benchmarks) + Terrascan (OPA mapping)

3) Secret scanning: KICS + git-secrets

So, the pipeline is: 
tfsec on PR (fast) -> Checkov/Terrascan/KICS in CI
