# Lab 10 — Vulnerability Management & Response with DefectDojo

### Key Program Metrics
- **Open vs. Closed**: 90 active, 0 mitigated findings
- **Findings Distribution by Tool**:
  - Dependency Scanners (Trivy): 36 findings (8 Critical, 28 High)
  - SAST (Semgrep): 41 findings (all Medium severity)
  - DAST (ZAP): 1 finding (Low severity) 
  - Reconnaissance (Nuclei): 12 findings (Informational)
- **SLA Status**: Findings with SLA less 14 days:
  - GHSA-c7hr-j4mj-j2w6 in jsonwebtoken:0.4.0
  - GHSA-xwcq-pm8m-c4vf in crypto-js:3.3.0 
  - GHSA-cchq-frgv-rjh5 in vm2:3.9.17
  - GHSA-c7hr-j4mj-j2w6 in jsonwebtoken:0.1.0
  - GHSA-whpj-8f3w-67p5 in vm2:3.9.17 
  - GHSA-jf85-cpcp-j695 in lodash:2.4.2
  - GHSA-5mrr-rgp6-x4gr in marsdb:0.6.11
  - GHSA-g644-9gfx-q4q4 in vm2:3.9.17
- **Top Risk Areas**: Third-party dependencies (vm2, jsonwebtoken, lodash) and
  - CWE-89: Improper Neutralization of Special Elements used in an SQL Command ('SQL Injection')
  - CWE-798: Use of Hard-coded Credentials
  - CWE-79: Improper Neutralization of Input During Web Page Generation ('Cross-site Scripting')
  - CWE-95: Improper Neutralization of Directives in Dynamically Evaluated Code ('Eval Injection')
  - CWE-548: Exposure of Information Through Directory Listing
  - CWE-601: URL Redirection to Untrusted Site ('Open Redirect')