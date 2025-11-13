# Lab 4 Submission: SBOM Generation & SCA for OWASP Juice Shop

## Task 1: SBOM Generation & Analysis

### 1.1 SBOM Generation

**Syft Artifacts:**
- `juice-shop-syft-native.json`: Complete package and dependency list in JSON format.
- `juice-shop-syft-table.txt`: Table summarizing key package details.

**Trivy Artifacts:**
- `juice-shop-trivy-detailed.json`: Comprehensive report on packages, vulnerabilities, and configuration.
- `juice-shop-trivy-table.txt`: Table with vulnerabilities and their severity.

### 1.2 Package Type & Dependency Analysis

#### Package Type Distribution Comparison (Syft vs Trivy)
- **Syft:** Detected 1 binary, 10 deb, and 1128 npm packages.
- **Trivy:** Found a similar set of npm and deb packages (see `trivy-package-counts.txt`).
- **Packages found by both tools:** 1126
- **Unique to Syft:** 13 packages
- **Unique to Trivy:** 9 packages

#### Dependency Discovery Analysis
Both tools identified nearly the same set of dependencies, with 1126 in common. Syft reported 13 unique packages, while Trivy found 9 that Syft missed. Trivy occasionally merges versions or omits minor dependencies, but overall, the coverage is very close. For Node.js, both tools provide a thorough view of dependencies, though Syft tends to be a bit stricter in its reporting.

### 1.3 License Discovery Analysis
- **Syft:** 31 unique license types
- **Trivy:** 28 unique license types
Both tools accurately identify major licenses such as MIT, ISC, and Apache-2.0. Syft picks up a few more rare or combined licenses, while Trivy conveniently separates OS and Node.js licenses. Overall, both provide enough license information for compliance needs.

---

## Task 2: SCA Results

### 2.1 SCA Tool Comparison — Vulnerability Detection Capabilities
- **Grype:** 58 unique CVEs (8 critical, 21 high, 23 medium, 1 low, 12 negligible)
- **Trivy:** 62 unique CVEs (8 critical, 23 high, 23 medium, 16 low)
- **CVEs found by both tools:** 15
Both tools are effective at finding vulnerabilities in npm and deb packages, with Trivy surfacing a few more low-priority issues.

### 2.2 Critical Vulnerabilities Analysis — Top 5 Most Critical Findings with Remediation
**Top 5 critical vulnerabilities (Grype):**
1. **vm2** (GHSA-whpj-8f3w-67p5, GHSA-g644-9gfx-q4q4, GHSA-cchq-frgv-rjh5) — update to at least 3.9.18
2. **jsonwebtoken** (GHSA-c7hr-j4mj-j2w6) — update to at least 4.2.2
3. **lodash** (GHSA-jf85-cpcp-j695) — update to at least 4.17.21
4. **crypto-js** (GHSA-xwcq-pm8m-c4vf) — update to at least 4.2.0
5. **lodash** (GHSA-4xc9-xhrj-v574) — update to at least 4.17.11

All of these are npm package vulnerabilities. The best course of action is to update the affected dependencies to the recommended safe versions.

### 2.3 License Compliance Assessment — Risky Licenses and Compliance Recommendations
- **Syft:** 31 unique license types
- **Trivy:** 28 unique license types
Risky licenses (GPL, LGPL, Artistic, WTFPL) are present but rare. For organizations, it’s wise to avoid or review packages with these licenses before use.

### 2.4 Additional Security Features — Secrets Scanning Results
Trivy’s secrets scan found no exposed secrets in the Juice Shop image, indicating no accidental inclusion of sensitive keys or tokens.

---

## Task 3: Toolchain Comparison & Recommendations

### 3.1 Accuracy Analysis — Package Detection and Vulnerability Overlap Quantified
- **Packages found by both tools:** 1126
- **Unique to Syft+Grype:** 13 packages
- **Unique to Trivy:** 9 packages
- **CVEs found by Grype:** 58
- **CVEs found by Trivy:** 62
- **CVEs in common:** 15
Each tool finds some unique vulnerabilities, so using both increases overall coverage.

### 3.2 Tool Strengths and Weaknesses — Practical Observations from Testing
- **Syft+Grype:**
  - Pros: Modular, detailed SBOMs, flexible integration, high detail for licenses and dependencies.
  - Cons: More manual steps, less convenient for quick scans, CI/CD integration takes extra setup.
- **Trivy:**
  - Pros: All-in-one, fast, simple, supports multiple scan types (vulnerabilities, licenses, secrets), easy to automate.
  - Cons: SBOMs are a bit less detailed, sometimes misses edge cases, less flexible output.

### 3.3 Use Case Recommendations — When to Choose Syft+Grype vs Trivy
- **Trivy** is a great fit for CI/CD, automation, and regular scans where speed and simplicity matter.
- **Syft+Grype** are better for compliance, deep audits, and integration with external vulnerability management systems, especially when you need maximum detail and control.
- For critical systems or final audits, using both tools is the best way to ensure nothing is missed.

### 3.4 Integration Considerations — CI/CD, Automation, and Operational Aspects
- **Trivy** integrates easily with CI/CD platforms (GitHub Actions, GitLab CI, Jenkins), supports automatic database updates, and is simple to use in Docker.
- **Syft+Grype** require a bit more setup but allow for custom pipelines and integration with platforms like Anchore or DefectDojo, and support export to CycloneDX/SPDX.
- Both tools work well in headless mode and can be automated, but Trivy is easier for quick adoption, while Syft+Grype are better for more complex workflows.

---
