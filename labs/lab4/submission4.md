## Task 1
### Package Type Distribution
Syft Package Counts:
- 1 binary
- 10 deb
- 1128 npm

Trivy Package Counts:
- 10 bkimminich/juice-shop:v19.0.0 (debian 12.11) 
- 1125 Node.js

Dependency Discovery Analysis - which tool found more/better dependency data


### License Discovery Analysis
- Trivy found 1113 Licenses
- Syft found 1146 Licenses

## Task 2

### SCA Tool Comparison
Grype Vulnerabilities by Severity:
      8 Critical
     21 High
      1 Low
     23 Medium
     12 Negligible

Trivy Vulnerabilities by Severity:
      8 CRITICAL
     23 HIGH
     16 LOW
     23 MEDIUM

### Critical Vulnerabilities Analysis - top 5 most critical findings with remediation
- **NAME:** vm2  
  - **INSTALLED:** 3.9.17  
  - **FIXED IN:** 3.9.18  
  - **TYPE:** npm  
  - **VULNERABILITY:** GHSA-whpj-8f3w-67p5  
  - **SEVERITY:** Critical  
  - **EPSS:** 69.5% (98th)  
  - **RISK:** 65.3  

- **NAME:** jsonwebtoken  
  - **INSTALLED:** 0.1.0  
  - **FIXED IN:** 4.2.2  
  - **TYPE:** npm  
  - **VULNERABILITY:** GHSA-c7hr-j4mj-j2w6  
  - **SEVERITY:** Critical  
  - **EPSS:** 41.1% (97th)  
  - **RISK:** 37.0  

- **NAME:** jsonwebtoken  
  - **INSTALLED:** 0.4.0  
  - **FIXED IN:** 4.2.2  
  - **TYPE:** npm  
  - **VULNERABILITY:** GHSA-c7hr-j4mj-j2w6  
  - **SEVERITY:** Critical  
  - **EPSS:** 41.1% (97th)  
  - **RISK:** 37.0  

- **NAME:** vm2  
  - **INSTALLED:** 3.9.17  
  - **FIXED IN:** (not fixed)  
  - **TYPE:** npm  
  - **VULNERABILITY:** GHSA-g644-9gfx-q4q4  
  - **SEVERITY:** Critical  
  - **EPSS:** 35.6% (96th)  
  - **RISK:** 33.4  

- **NAME:** vm2  
  - **INSTALLED:** 3.9.17  
  - **FIXED IN:** (not fixed)  
  - **TYPE:** npm  
  - **VULNERABILITY:** GHSA-cchq-frgv-rjh5  
  - **SEVERITY:** Critical  
  - **EPSS:** 4.7% (88th)  
  - **RISK:** 4.4  

### License Compliance Assessment - risky licenses and compliance recommendations

GPL license can by risky for commercial projects

### Additional Security Features - secrets scanning results

- **High severity**: 2 RSA private keys
- **Medium severity**: 2 JWT tokens


## Task 3

### Accuracy Analysis - package detection and vulnerability overlap quantified

=== Package Detection Comparison ===
- Packages detected by both tools: 1126
- Packages only detected by Syft: 13
- Packages only detected by Trivy: 9

=== Vulnerability Detection Overlap ===
- CVEs found by Grype: 58
- CVEs found by Trivy: 62
- Common CVEs: 15

### Tool Strengths and Weaknesses - practical observations from your testing



### Use Case Recommendations - when to choose Syft+Grype vs Trivy

Choose **Trivy**: if speed is essential, easy for newcomers.

Choose **Syft + Grype**: when you need both vulnerability scanning and SBOM generation

### Integration Considerations - CI/CD, automation, and operational aspects

**CI/CD Integration:**
- Easier for Syft+Grype, Trivy requires some configuration

**Operational Overhead:**
- Trivy just one tool, it's easier to maintain.