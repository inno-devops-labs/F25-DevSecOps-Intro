# Lab 6 — Infrastructure-as-Code Security: Scanning & Policy Enforcement

## Tasks

### Task 1 — Terraform & Pulumi Security Scanning

#### Terraform Tool Comparison

- **tfsec**: 53 findings (18 passed, 9 critical, 25 high, 11 medium, 8 low)
- **Checkov**: 78 findings (48 passed, 78 failed)
- **Terrascan**: 22 findings (14 high, 8 medium, 0 low)

#### Pulumi Security Analysis

**KICS Pulumi findings:**

- **Total**: 6
- **CRITICAL**: 0
- **HIGH Severity**: 2
- **MEDIUM Severity**: 2
- **LOW Severity**: 0
- **INFO**: 2

#### Terraform vs. Pulumi

Terraform has many critical and high severity issues, and more issues detected overall. This may be the case because of more mature ecosystem, with more tools for detection, and high overlap between them

Pulumi has a lot less findings, with zero critical issues. Only KICS supports Pulumi for now.

#### KICS Pulumi Support

Pulumi-specific Quary Catalog has lot less coverage that Terraform's, detects mostly basic or high-severity issues

#### Critical Findings

- **Terraform** has 14 high issues. Mostly has simple misconfigurations (Security Groups, disabled logging, exposure, some tech support disabled) which still can lead to catastrophic results. 8 out of 9 CRITICAL issues related to Security group misconfiguration, and ne CRITICAL issue is instance exposure.
- **Pulumi** - has 2 similar issues, but no detection in less obvious issues (Only generic password and no encryption in dynamodb detected as high severity)

#### Tool strengths

- **tfsec** is very fast, provides detailed description and fixes for detected issues.
- **Checkov** detected most issue for this lab. Has broad coverage for various cloud providers, low false-positive rate
- **Terrascan** - Terrascan has large policy library, supports policy-as-code and many cloud providers
- **KICS** - Basic Pulumi coverage, especially for severe and very basic issues, minimal configuration needed.

### Task 2 - Ansible Security Scanning with KICS
- **Ansible Security Issues** 

KICS Detected 8 HIGH, and 1 LOW severity issues. But in reality its 2 cases of password in url, 6 generic password, and case of unpinned package version.

- **Best Practice Violations**

Two issues are obvious:
HIGH Generic password and Password in URL mean basically the same. Anyone who can see ansible playbooks can find passwords in them. They should be kept secret in other way, or requiested each run.
Last issue is unpinned version, so any malicious update in external package can lead to issues within our system.

- **KICS Ansible Queries**

In our case KICS detected secrets management (Sensitive data, such as passwords and tokens in playbooks) type of issues.
Others are configuration hardening (various permissions, roles, groups), network security (enforcement of SSL/TLS and other secure protocols, ACM validations and exposures), and execution safety (various injections, input validations bypasses etc)

- **Remediation Steps**

Almost all detected issues - password exposure. Use adopted secret management technicues instead of plaintext in playbooks.
Other issue can be fixed by changing `:latest` in package version, to it's current version. So updates in package can't harm system by themselves.

### Task 3 - Comparative Tool Analysis & Security Insights

- **Tool effectiveness Matrix**

   | Criterion | tfsec | Checkov | Terrascan | KICS |
   |-----------|-------|---------|-----------|------|
   | **Total Findings** | 53 | 78 | 22 |  6(Pulumi) 9(Ansible) |
   | **Scan Speed** | Fast | Medium | Medium | Medium |
   | **False Positives** | Low | Medium | Medium | Medium |
   | **Report Quality** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
   | **Ease of Use** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
   | **Documentation** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
   | **Platform Support** | Terraform only | Multiple | Multiple | Multiple |
   | **Output Formats** | JSON, text, SARIF, etc | | | |
   | **CI/CD Integration** | Easy | Easy | Medium | Easy |
   | **Unique Strengths** | Terraform-specific, Fast | Broad coverage | Policy-as-code | Pulumni+Ansible support |

- **Vulnerability Category Analysis**

    | Security Category | tfsec | Checkov | Terrascan | KICS (Pulumi) | KICS (Ansible) | Best Tool |
   |------------------|-------|---------|-----------|---------------|----------------|----------|
   | **Encryption Issues** | 8 | 12 | 5 | 1 | 0 | **Checkov** |
   | **Network Security** | 11 | 18 | 6 | 2 | 1 | **Checkov** |
   | **Secrets Management** | 7 | 14 | 4 | 0 | 8 | **KICS** |
   | **IAM/Permissions** | 9 | 15 | 3 | 1 | 0 | **Checkov** |
   | **Access Control** | 6 | 10 | 2 | 1 | 0 | **Checkov** |
   | **Compliance/Best Practices** | 12 | 9 | 2 | 1 | 0 | **tfsec** |

- **Top 5 Critical Findings**

1. Plaintext passwords in ansible playbooks
    Remediation: use ansible vault or other secret management tools

2. Missing SSL/TLS Enforcement
    Remediation: configure pulumi/kubernetes to use SSL/TLS

3. Public S3 Buckets
    Remediation: set acl = "private", enable encryption

4. Wildcard IAM Policies
    Remediation: Allow only privileges neccessary to work

5. Open Security Groups
    Remediation: Restrict ingress CIDR blocks

- **Tool Selection gude**
Use tfsec/Checkov for terraform-only projects.
Use Checkov/Terrascan if others aren't native to cloud
Use Terrascan/Checkov if policy-as-code required
Use KICS if pulumi present

In reality there's usually no reason not to use them all (or at least most of them) in pipeline to miximize the coverage.

- **Lessons Learned**
Almost all tools have false-positives, some policies may be needed to ensure that after becoming true-positive they won't be forgotten
No tool can cover everything, more tools (although not linearly) improve coverage
No tool can even check every part of the project, some things (pulumi) can be covered only by small amount of tools

- **CI/CD Integration Strategy**
Use fast basic tools at pre-commit (like tfsec).
Use more broad and slower tools at PR Check (Checkov, Terrascan)
Recheck everything at release, using as many tools as needed


