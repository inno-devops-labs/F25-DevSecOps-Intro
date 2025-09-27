# Lab 4 Submission: SBOM Generation & Software Composition Analysis

## Executive Summary

This lab demonstrates comprehensive Software Bill of Materials (SBOM) generation and Software Composition Analysis (SCA) using modern security tools. We analyzed the OWASP Juice Shop application (v19.0.0) using both specialized toolchains (Syft+Grype) and integrated solutions (Trivy), providing quantitative comparisons of their capabilities in package detection, vulnerability scanning, and license analysis.

**Key Findings:**
- **Package Detection**: 1,139 total packages detected (1,126 common, 13 Syft-only, 9 Trivy-only)
- **Vulnerability Coverage**: 65 total CVEs found (13 common between tools)
- **License Discovery**: 31 unique license types identified by Syft, 28 by Trivy
- **Security Issues**: 4 secrets detected, including RSA private keys and JWT tokens

---

## Task 1: SBOM Generation with Syft and Trivy

### 1.1 Package Type Distribution Analysis

**Syft Package Detection:**
- **npm packages**: 1,128 (99.1% of total)
- **deb packages**: 10 (0.9% of total)  
- **binary files**: 1 (0.1% of total)

**Trivy Package Detection:**
- **Node.js packages**: 1,125 (99.1% of total)
- **OS packages (Debian)**: 10 (0.9% of total)

### 1.2 Dependency Discovery Analysis

**Quantitative Comparison:**
- **Common packages detected by both tools**: 1,126 (98.9% overlap)
- **Packages unique to Syft**: 13 (1.1% additional coverage)
- **Packages unique to Trivy**: 9 (0.8% additional coverage)

**Syft-Only Packages Include:**
- System libraries: `libc6`, `libssl3`, `libstdc++6`
- Development tools: `gcc-12-base`, `libgomp1`
- Node.js runtime: `node@22.18.0`
- Timezone data: `tzdata`

**Trivy-Only Packages Include:**
- Additional system libraries with different versioning
- Some npm packages with version discrepancies

### 1.3 License Discovery Analysis

**Syft License Detection:**
- **Total unique licenses**: 31 types
- **Most common**: MIT (888 occurrences, 78.7%)
- **Other significant**: ISC (143), Apache-2.0 (19), BSD-3-Clause (14)
- **Notable findings**: GPL variants (17 total), LGPL (25 total)

**Trivy License Detection:**
- **OS packages**: 15 unique license types
- **Node.js packages**: 28 unique license types  
- **Most common**: MIT (878), ISC (143), Apache-2.0 (12)

**License Compliance Assessment:**
- **High-risk licenses detected**: GPL-2.0, GPL-3.0, LGPL variants
- **Recommendation**: Review GPL/LGPL dependencies for compliance requirements
- **Low-risk licenses**: MIT, ISC, Apache-2.0 (permissive licenses)

---

## Task 2: Software Composition Analysis with Grype and Trivy

### 2.1 SCA Tool Comparison

**Grype Vulnerability Detection:**
- **Total vulnerabilities**: 65 CVEs
- **Critical**: 8 (12.3%)
- **High**: 20 (30.8%)
- **Medium**: 24 (36.9%)
- **Low**: 1 (1.5%)
- **Negligible**: 12 (18.5%)

**Trivy Vulnerability Detection:**
- **Total vulnerabilities**: 70 CVEs
- **Critical**: 8 (11.4%)
- **High**: 23 (32.9%)
- **Medium**: 24 (34.3%)
- **Low**: 15 (21.4%)

### 2.2 Critical Vulnerabilities Analysis

**Top 5 Most Critical Findings:**

1. **vm2@3.9.17** - Multiple Critical CVEs
   - **CVE**: GHSA-whpj-8f3w-67p5 (Critical, EPSS: 69.5%)
   - **Risk**: 65.3 (highest risk score)
   - **Remediation**: Update to vm2@3.9.18+

2. **jsonwebtoken@0.1.0 & 0.4.0** - Critical JWT vulnerabilities
   - **CVE**: GHSA-c7hr-j4mj-j2w6 (Critical, EPSS: 41.1%)
   - **Risk**: 37.0
   - **Remediation**: Update to jsonwebtoken@4.2.2+

3. **lodash@2.4.2** - Prototype pollution
   - **CVE**: GHSA-jf85-cpcp-j695 (Critical, EPSS: 3.4%)
   - **Risk**: 3.1
   - **Remediation**: Update to lodash@4.17.12+

4. **crypto-js@3.3.0** - Cryptographic vulnerabilities
   - **CVE**: GHSA-xwcq-pm8m-c4vf (Critical, EPSS: 1.0%)
   - **Risk**: 0.9
   - **Remediation**: Update to crypto-js@4.2.0+

5. **ip@2.0.1** - IP address validation bypass
   - **CVE**: GHSA-2p57-rm9w-gvfp (High, EPSS: 2.9%)
   - **Risk**: 2.3
   - **Remediation**: Update to latest version

### 2.3 Additional Security Features

**Secrets Scanning Results (Trivy):**
- **Total secrets found**: 4
- **High severity**: 2 (RSA private keys in source code)
- **Medium severity**: 2 (JWT tokens in test files)
- **Files affected**: 
  - `/juice-shop/lib/insecurity.ts` (RSA private key)
  - `/juice-shop/build/lib/insecurity.js` (RSA private key)
  - Test files with hardcoded JWT tokens

**License Compliance Summary:**
- **Syft found**: 31 unique license types
- **Trivy found**: 28 unique license types
- **Compliance risk**: Multiple GPL/LGPL dependencies require careful review

---

## Task 3: Comprehensive Toolchain Comparison

### 3.1 Accuracy Analysis

**Package Detection Accuracy:**
- **Overlap**: 98.9% (1,126/1,139 packages detected by both)
- **Syft advantage**: Better system-level package detection (13 additional packages)
- **Trivy advantage**: More comprehensive Node.js ecosystem coverage (9 additional packages)

**Vulnerability Detection Overlap:**
- **Grype CVEs**: 58 unique vulnerabilities
- **Trivy CVEs**: 62 unique vulnerabilities  
- **Common CVEs**: 13 (22.4% overlap)
- **Tool-specific findings**: 45 Grype-only, 49 Trivy-only

### 3.2 Tool Strengths and Weaknesses

**Syft+Grype Toolchain:**

*Strengths:*
- Superior system-level package detection
- More detailed license information
- Better integration between SBOM generation and vulnerability scanning
- Comprehensive metadata extraction

*Weaknesses:*
- Requires two separate tools
- More complex setup and maintenance
- Limited built-in secret scanning

**Trivy All-in-One:**

*Strengths:*
- Single tool for all security scanning needs
- Built-in secret scanning capabilities
- Excellent CI/CD integration
- Comprehensive vulnerability database

*Weaknesses:*
- Less detailed license information
- Some system packages missed
- Single point of failure

### 3.3 Use Case Recommendations

**Choose Syft+Grype when:**
- Detailed license compliance is critical
- System-level security is a priority
- Maximum metadata extraction is needed
- Working with complex multi-layer containers

**Choose Trivy when:**
- Simplicity and ease of use are priorities
- CI/CD integration is important
- Secret scanning is required
- Single-tool solution is preferred
- Rapid vulnerability scanning is needed

### 3.4 Integration Considerations

**CI/CD Integration:**
- **Trivy**: Excellent with built-in CI/CD support, GitHub Actions, GitLab CI
- **Syft+Grype**: Requires custom pipeline configuration, more complex setup

**Operational Overhead:**
- **Trivy**: Single tool maintenance, easier updates
- **Syft+Grype**: Two tools to maintain, more complex dependency management

**Performance:**
- **Trivy**: Faster execution for basic scans
- **Syft+Grype**: More thorough but slower analysis

---

## Security Recommendations

### Immediate Actions Required:
1. **Update vm2 to 3.9.18+** - Critical vulnerability with high exploitability
2. **Update jsonwebtoken to 4.2.2+** - Critical JWT security issues
3. **Remove hardcoded private keys** from source code
4. **Update lodash to 4.17.12+** - Prototype pollution vulnerability

### License Compliance:
1. **Audit GPL/LGPL dependencies** for compliance requirements
2. **Document license obligations** for all dependencies
3. **Consider alternatives** for restrictive licenses if needed

### Long-term Security Strategy:
1. **Implement automated vulnerability scanning** in CI/CD pipeline
2. **Regular dependency updates** and security patches
3. **SBOM generation** for all production releases
4. **License compliance monitoring** and reporting

---

## Conclusion

This analysis demonstrates the complementary nature of modern SBOM and SCA tools. While Trivy provides excellent all-in-one capabilities for most use cases, the Syft+Grype combination offers superior depth for organizations requiring detailed license compliance and system-level security analysis. The 98.9% package detection overlap indicates both toolchains are highly effective, with the choice depending on specific organizational requirements and operational constraints.

The discovery of 4 secrets and 65+ vulnerabilities highlights the critical importance of comprehensive security scanning in modern software development, particularly for applications handling sensitive data like OWASP Juice Shop.
