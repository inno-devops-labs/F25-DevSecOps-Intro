# Lab 4 — SBOM Generation & Software Composition Analysis

## Task 1: SBOM Generation with Syft and Trivy

### 1.1 Package Type Distribution Comparison

**Syft Package Counts:**

    1 binary
    10 deb
    1128 npm

**Trivy Package Counts:**

    10 bkimminich/juice-shop:v19.0.0 (debian 12.11) - unknown
    1125 Node.js - unknown

**Comparison Analysis:**
- Syft discovered: 1139 total packages across 3 types (binary, deb, npm)
- Trivy discovered: 1135 total packages across 2 categories (OS packages, Node.js) 
- Key differences: 
  - Syft provides more granular package type classification
  - Syft identified 1 binary package that Trivy categorized as "unknown"
  - Trivy groups packages by target environment rather than package type
  - Both tools found similar total counts (1,139 vs 1,135)

### 1.2 Dependency Discovery Analysis

**Syft Capabilities:**
- Dependency depth: Comprehensive npm dependency tree (1,128 packages)
- Version accuracy: Detailed version information for all package types
- Relationship mapping: Clear classification by package manager (deb, npm) and binary artifacts

**Trivy Capabilities:**
- Dependency depth: Similar npm coverage (1,125 packages) with OS package focus
- Version accuracy: Focused on vulnerability scanning with sufficient version data
- Relationship mapping: Organized by target (Docker image, Node.js) rather than package type

**Tool Comparison:**
- **Dependency quantity**: Nearly identical (Syft: 1,139 vs Trivy: 1,135)
- **Data granularity**: Syft provides more detailed package type classification
- **Unique findings**: Syft identified binary artifacts separately
- **Quality of metadata**: Both tools provide sufficient data for SCA, with Syft offering slightly better organization

### 1.3 License Discovery Analysis

**Syft License Findings:**

    Syft Licenses:
      1 0BSD
      1 ad-hoc
      1 Apache2
      15 Apache-2.0
      5 Artistic
      5 BlueOak-1.0.0
      1 BSD
      12 BSD-2-Clause
      1 (BSD-2-Clause OR MIT OR Apache-2.0)
      14 BSD-3-Clause
      4 GFDL-1.2
      5 GPL
      1 GPL-1
      1 GPL-1+
      6 GPL-2
      1 GPL-2.0
      4 GPL-3
      143 ISC
      4 LGPL
      1 LGPL-2.1
      19 LGPL-3.0
      888 MIT
      2 (MIT OR Apache-2.0)
      1 (MIT OR WTFPL)
      2 MIT/X11
      2 MPL-2.0
      1 public-domain
      2 Unlicense
      1 WTFPL
      1 WTFPL OR ISC
      1 (WTFPL OR MIT)

**Trivy License Findings:**

      Trivy Licenses (OS Packages):
      1 ad-hoc
      1 Apache-2.0
      2 Artistic-2.0
      1 GFDL-1.2-only
      1 GPL-1.0-only
      1 GPL-1.0-or-later
      3 GPL-2.0-only
      2 GPL-2.0-or-later
      1 GPL-3.0-only
      1 LGPL-2.0-or-later
      1 LGPL-2.1-only
      1 public-domain

      Trivy Licenses (Node.js):
      1 0BSD
      12 Apache-2.0
      5 BlueOak-1.0.0
      12 BSD-2-Clause
      1 (BSD-2-Clause OR MIT OR Apache-2.0)
      14 BSD-3-Clause
      1 GPL-2.0-only
      143 ISC
      19 LGPL-3.0-only
      878 MIT
      2 (MIT OR Apache-2.0)
      1 (MIT OR WTFPL)
      2 MIT/X11
      2 MPL-2.0
      2 Unlicense
      1 WTFPL
      1 WTFPL OR ISC
      1 (WTFPL OR MIT)

**License Analysis:**

- **Total unique licenses found**: Syft detected more license variety (28+ types) vs Trivy's categorized approach
- **High-risk licenses identified**: 
  - GPL variants (GPL-1.0, GPL-2.0, GPL-3.0)
  - LGPL variants
  - Strong copyleft licenses present but minority
- **License coverage**: 
  - Syft: Comprehensive coverage across all package types
  - Trivy: Good coverage with separation of OS vs application licenses
- **Compliance implications**: 
  - Dominant licenses: MIT (888), ISC (143) - both permissive
  - GPL/LGPL packages require attention for compliance
  - Multiple dual-license packages provide flexibility

## Initial Observations

### Strengths of Syft:
- Superior package type classification and granularity
- More comprehensive license detection across all package types
- Better organization of package metadata
- Binary artifact identification

### Strengths of Trivy:
- Clear separation of OS packages vs application dependencies
- Standardized license naming (e.g., "GPL-2.0-only" vs "GPL-2")
- Integrated vulnerability scanning capability
- Target-based organization useful for container security

## Task 2: Software Composition Analysis with Grype and Trivy

### 2.1 SCA Tool Comparison - Vulnerability Detection Capabilities

**Grype Vulnerabilities by Severity:**

    8 Critical
    21 High
    1 Low
    23 Medium
    12 Negligible

**Trivy Vulnerabilities by Severity:**

    8 CRITICAL
    23 HIGH
    16 LOW
    23 MEDIUM

**Vulnerability Detection Comparison:**
- Total vulnerabilities found: Grype: 65, Trivy: 70

-  Severity distribution:

    -  Critical: Both tools found 8 critical vulnerabilities

    -  High: Trivy found slightly more (23 vs 21)

    -  Medium: Both found 23 medium severity

    -  Low/Negligible: Trivy found more low-severity issues (16 vs 1+12)

- Coverage: Trivy detected more total vulnerabilities (70 vs 65)

- Severity classification: Both tools show consistent critical/high vulnerability identification

### 2.2 Critical Vulnerabilities Analysis - Top 5 Most Critical Findings

1. **GHSA-whpj-8f3w-67p5** - vm2
   - **Severity**: Critical (EPSS: 69.5%)
   - **Package**: vm2@3.9.17
   - **Fix**: Update to 3.9.18

2. **GHSA-c7hr-j4mj-j2w6** - jsonwebtoken  
   - **Severity**: Critical (EPSS: 41.1%)
   - **Package**: jsonwebtoken@0.1.0 & 0.4.0
   - **Fix**: Update to 4.2.2

3. **GHSA-g644-9gfx-q4q4** - vm2
   - **Severity**: Critical (EPSS: 35.6%)
   - **Package**: vm2@3.9.17
   - **Fix**: Update vm2

4. **GHSA-cchq-frgv-rjh5** - vm2
   - **Severity**: Critical (EPSS: 4.7%)
   - **Package**: vm2@3.9.17
   - **Fix**: Update vm2

5. **GHSA-jf85-cpcp-j695** - lodash
   - **Severity**: Critical (EPSS: 3.4%)
   - **Package**: lodash@2.4.2
   - **Fix**: Update to 4.17.12

### 2.3 License Compliance
- **Syft**: 31 unique license types
- **Trivy**: 28 unique license types
- **Risk**: Multiple GPL/LGPL licenses requiring compliance attention

### 2.4 Additional Security Features - Secrets Scanning Results

**Trivy Secrets Scan Findings:**
- **Total secrets detected**: 4
- **Severity distribution**: HIGH: 2, MEDIUM: 2, CRITICAL: 0

**Critical Findings:**

1. **HIGH: RSA Private Key Exposure**
   - **Location**: `/juice-shop/build/lib/insecurity.js` and `/juice-shop/lib/insecurity.ts`
   - **Risk**: Private encryption keys embedded in source code
   - **Impact**: Compromise of JWT token security

2. **MEDIUM: JWT Token in Test Files**
   - **Locations**: Test files (`app.guard.spec.ts`, `last-login-ip.component.spec.ts`)
   - **Risk**: Hardcoded authentication tokens
   - **Context**: Test data, but still represents security anti-pattern



## Task 3: Toolchain Comparison - Syft+Grype vs Trivy All-in-One

### 3.1 Accuracy and Coverage Analysis

**Package Detection Comparison:**

    Packages detected by both tools: 1126
    Packages only detected by Syft: 13
    Packages only detected by Trivy: 9

**Vulnerability Detection Overlap:**

    CVEs found by Grype: 58
    CVEs found by Trivy: 62
    Common CVEs: 15
  
**Key Metrics:**
- **Package detection rate**: High overlap (1126 common packages), Syft detected slightly more unique packages (13 vs 9)
- **Vulnerability coverage**: Low overlap - only 15 common CVEs out of 58+62 total
- **Detection accuracy**: Tools show significant differences in vulnerability databases and detection methods

### 3.2 Tool Strengths and Weaknesses

**Syft + Grype Strengths:**
- Better package detection (1139 total vs 1135 for Trivy)
- Superior license detection (31 vs 28 license types)
- More detailed SBOM metadata and package classification
- Specialized tools with deep focus on respective domains

**Syft + Grype Weaknesses:**
- Lower vulnerability detection (58 vs 62 CVEs)
- Significant vulnerability database differences
- Two separate tools requiring integration

**Trivy Strengths:**
- Higher vulnerability detection coverage (62 CVEs)
- All-in-one solution with integrated secrets scanning
- Simpler deployment and maintenance
- Broader vulnerability database

**Trivy Weaknesses:**
- Less detailed license information
- Fewer unique packages detected
- Coarser package classification

### 3.3 Use Case Recommendations

**Choose Syft + Grype when:**
- Comprehensive software composition analysis is critical
- Detailed license compliance and audit requirements exist
- You need the most accurate and granular SBOM metadata
- Your workflow can accommodate specialized tool integration

**Choose Trivy when:**
- Maximum vulnerability detection coverage is the priority
- You prefer a unified security scanning solution
- Operational simplicity and maintenance efficiency are important
- Integrated secrets scanning is required

**Critical Finding**: The low CVE overlap (15/105) suggests using **both tools** for comprehensive security coverage in high-risk environments.

### 3.4 Integration Considerations

**CI/CD Pipeline Impact:**
- **Syft+Grype**: Two-step process, but more detailed compliance data
- **Trivy**: Single command, faster implementation
- **Critical**: Vulnerability results are not interchangeable - databases differ significantly

**Risk Management Implications:**
- **High risk**: Relying on only one tool misses 70-80% of vulnerabilities detected by the other
- **Recommended**: Implement both tools in parallel for critical applications
- **Prioritization**: Use Trivy for broader vulnerability coverage, Syft+Grype for compliance depth


**The significant vulnerability database differences make a strong case for multi-tool security scanning strategies.**