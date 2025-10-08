# Lab 4 — SBOM Generation & Software Composition Analysis

## Task 1 — SBOM Generation with Syft and Trivy

### Package Type Distribution

**Syft Package Counts:**

- Binary: 1 package
- DEB: 10 packages
- NPM: 1,128 packages
- **Total:** 1,139 packages

**Trivy Package Counts:**

- OS Packages (Debian): 10 packages
- Node.js: 1,125 packages
- **Total:** 1,135 packages
### Dependency Discovery Analysis

- Syft detected 4 more packages than Trivy
- Syft provides better package type identification
- Trivy groups packages by target platforms
- Both tools show similar overall dependency counts
### License Discovery Analysis

- Syft discovered 1,139 license entries
- Trivy discovered 1,091 license entries
- Syft employs more aggressive license detection strategies
- Trivy is more conservative but provides clear ecosystem separation
- Both tools identified potentially problematic licenses

## Task 2 — Software Composition Analysis with Grype and Trivy

### SCA Tool Comparison

Grype: 65 vulnerabilities total (8 Critical, 21 High, 23 Medium, 1 Low, 12 Negligible)

Trivy: 70 vulnerabilities total (8 CRITICAL, 23 HIGH, 23 MEDIUM, 16 LOW)

Key Differences:

- Trivy finds 5 more vulnerabilities overall (+2 High, +15 Low)
- Grype provides EPSS scores and better prioritization
- Both agree on 8 Critical vulnerabilities

### Critical Vulnerabilities Analysis

**Top 5 Critical Vulnerabilities:**

1. vm2@3.9.17 - GHSA-whpj-8f3w-67p5

	Fix: `npm update vm2@3.9.18`

3. jsonwebtoken@0.1.0/0.4.0 - GHSA-c7hr-j4mj-j2w6
   
	Fix: `npm update jsonwebtoken@4.2.2`

5. vm2@3.9.17 - GHSA-g644-9gfx-q4q4
   
	Fix: `npm update vm2@latest`

7. vm2@3.9.17 - GHSA-cchq-frgv-rjh5
   
	Fix: `npm update vm2@latest`

9. lodash@2.4.2 - GHSA-jf85-cpcp-j695
    
	Fix: `npm update lodash@4.17.21`

### License Compliance Assessment

**High-Risk Licenses:**

- GPL/LGPL family: 38+ packages - require source code disclosure
- Non-standard: WTFPL, Unlicense - legal uncertainty

**Tool Performance:**

- Syft: 31 license types (better for compliance)
- Trivy: 28 license types

### Additional Security Features

**Trivy Advantages:**

- Built-in secrets scanning
- Configuration scanning
- Single tool for multiple security checks

**Grype Advantages:**

- EPSS exploit probability scores
- Better risk prioritization
- Reduced alert fatigue

**Best Practice:** Use Trivy for development scans, Grype for production security.

## Task 3 — Toolchain Comparison: Syft+Grype vs Trivy All-in-One

### Accuracy Analysis

**Package Detection:**

- Syft unique: 13 packages
- Trivy unique: 9 packages
- **Common packages:** 1,126

**Vulnerability Detection:**

- Grype CVEs: 58 total
- Trivy CVEs: 62 total
- **Common CVEs:** 15 only

### Tool Strengths and Weaknesses

**Syft+Grype Strengths:**

- Superior package detection
- Better license discovery
- EPSS scoring for exploit probability
- Risk-based prioritization

**Syft+Grype Weaknesses:**

- Lower total vulnerability count
- Two-tool complexity
- Steeper learning curve

**Trivy Strengths:**

- Higher vulnerability detection
- Single-tool simplicity
- Better CI/CD integration

**Trivy Weaknesses:**

- Less accurate package detection
- Poorer license coverage
- More low-severity noise

### Use Case Recommendations

**Syft+Grype for:**

- Enterprise security teams - Better risk prioritization
- Compliance-heavy environments - Superior license tracking
- Mature DevSecOps - Can handle two-tool complexity
- Regulated industries - Detailed audit trails required

**Trivy for:**

- Development teams - Fast, simple integration
- Startups/SMBs - Limited security resources
- CI/CD pipelines - Single-tool simplicity
- Initial security programs - Gentle learning curve

### Integration Considerations

Syft+Grype: Higher maintenance (two tools)

Trivy: Lower maintenance (single tool)

Alert fatigue: Grype = Less, Trivy = More

Remediation: Grype = Faster (EPSS helps), Trivy = Slower

Compliance: Syft+Grype = Better
