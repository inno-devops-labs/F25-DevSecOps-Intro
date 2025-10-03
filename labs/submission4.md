# Lab 4 Submission - SBOM Generation & Software Composition Analysis

## Task 1: SBOM Generation with Syft and Trivy (4 pts)

**Package Detection Results:**
- Syft: 1,139 packages (1 binary + 10 Debian + 1,128 NPM)
- Trivy: 1,135 packages (1,125 Node.js + 10 Debian)
- **Overlap: 1,126 common packages (99.2%)**

**License Analysis:**
- Syft: 47 unique license types (888 MIT, 143 ISC, 19 LGPL-3.0)
- Trivy: ~30 unique license types
- Both tools effectively identified core dependencies

## Task 2: SCA with Grype and Trivy (3 pts)

**Vulnerability Detection:**
- Grype: 58 vulnerabilities (excellent SBOM integration)
- Trivy: 62 vulnerabilities (comprehensive scanning + secrets)

**Top Critical Vulnerabilities:**
1. **CVE-2022-23541 (jsonwebtoken)** - CVSS 6.3 → Update to v9.0.0
2. **CVE-2025-9230 (OpenSSL)** - CVSS 7.5 → Update to 3.0.17-1~deb12u3
3. **GHSA-gjcw-v447-2w7q (jws)** - CVSS 8.7 → Update to v3.0.0

**License Compliance:**
- **High Risk**: GPL-3.0 (4 packages) - viral copyleft
- **Low Risk**: MIT/ISC/Apache-2.0 (majority) - permissive
- **Recommendation**: Review GPL packages for commercial compatibility

## Task 3: Toolchain Comparison: Syft+Grype vs Trivy (3 pts)

**Detection Accuracy:**
- Package overlap: 99.2% (1,126 common packages)
- CVE overlap: 24.2% (15 common vulnerabilities)

**Tool Comparison:**

| Aspect | Syft+Grype | Trivy |
|--------|------------|-------|
| **Strengths** | Superior SBOM metadata, SPDX support | All-in-one, faster execution, CI/CD friendly |
| **Weaknesses** | Complex setup, two tools | Less detailed metadata |
| **Best for** | Enterprise compliance, regulatory requirements | DevOps simplicity, comprehensive scanning |

**Recommendation:**
- **Syft+Grype**: Enterprise environments requiring detailed SBOM compliance
- **Trivy**: DevOps teams prioritizing operational efficiency and comprehensive security scanning
