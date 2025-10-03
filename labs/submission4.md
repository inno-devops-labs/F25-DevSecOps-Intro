# Lab 4 Submission — SBOM Generation & Software Composition Analysis

## Task 1 — SBOM Generation with Syft and Trivy

### Package Type Distribution Comparison

Based on the SBOM analysis of OWASP Juice Shop v19.0.0:

**Syft Package Distribution:**
- npm packages: 1,128
- Debian packages: 10
- Binary packages: 1
- **Total packages: 1,139**

**Trivy Package Distribution:**
- Node.js packages: 1,125
- Debian packages: 10
- **Total packages: 1,135**

**Key Observations:**
- Syft detected 4 more packages than Trivy overall
- Both tools excel at Node.js/npm package detection (Syft: 1128, Trivy: 1125)
- Trivy provides better context by associating packages with their target environments (debian 12.11, Node.js runtime)
- Syft includes additional binary artifacts that Trivy may not classify as distinct package types

### Dependency Discovery Analysis

**Syft excels in comprehensive dependency discovery:**
- **Total packages detected:** 1,139 vs Trivy's 1,135
- **Better metadata extraction:** Syft provides detailed artifact information including file paths, digests, and relationship metadata
- **Package type granularity:** Syft distinguishes between npm, deb, and binary packages more precisely

**Trivy advantages:**
- **Runtime context awareness:** Associates packages with specific container layers and execution environments

### License Discovery Analysis

**License Detection Results:**
- **Syft:** 31
- **Trivy:** 28

**Syft License Advantages:**
- **Broader coverage:** Found 3 additional license types not detected by Trivy
- **Detailed license metadata:** Includes license expressions and SPDX identifiers
- **Comprehensive artifact association:** Links licenses directly to specific package versions

**Trivy License Features:**
- **OS package licenses:** Better detection of system-level package licenses (debian packages)
- **License compliance categorization:** Provides clearer license compliance assessment


## Task 2 — Software Composition Analysis with Grype and Trivy

### SCA Tool Comparison - Vulnerability Detection Capabilities

**Quantitative Comparison:**
- **Grype (via Syft SBOM):** 58 unique CVEs detected
- **Trivy (all-in-one):** 62 unique CVEs detected
- **Overlap:** 15 CVEs found by both tools
- **Unique to Grype:** 43 CVEs
- **Unique to Trivy:** 47 CVEs

### Critical Vulnerabilities Analysis - Top 5 Most Critical Findings

Based on CVSS scores, exploitability, and impact analysis:

1. **vm2 RCE Vulnerability (GHSA-whpj-8f3w-67p5)**
   - **Severity:** Critical (EPSS: 69.5%)
   - **Affected Package:** vm2 3.9.17
   - **Impact:** Remote Code Execution in sandboxed code execution
   - **Remediation:** Upgrade to vm2 >= 3.9.18 immediately

2. **jsonwebtoken Signature Verification Bypass (GHSA-c7hr-j4mj-j2w6)**
   - **Severity:** Critical (EPSS: 41.1%)
   - **Affected Packages:** jsonwebtoken 0.1.0, 0.4.0
   - **Impact:** Authentication bypass, privilege escalation
   - **Remediation:** Upgrade to jsonwebtoken >= 4.2.2 or use alternative JWT library

3. **vm2 Sandbox Escape (GHSA-g644-9gfx-q4q4)**
   - **Severity:** Critical (EPSS: 35.6%)
   - **Affected Package:** vm2 3.9.17
   - **Impact:** Code execution outside sandbox boundaries
   - **Remediation:** Upgrade to patched version or replace with safer alternatives

4. **crypto-js Weak Encryption (GHSA-xwcq-pm8m-c4vf)**
   - **Severity:** Critical (EPSS: 1.0%)
   - **Affected Package:** crypto-js 3.3.0
   - **Impact:** Insufficient encryption strength for security-critical operations
   - **Remediation:** Migrate to Node.js native crypto module or upgrade to crypto-js >= 4.2.0

5. **lodash Prototype Pollution (GHSA-jf85-cpcp-j695)**
   - **Severity:** Critical (EPSS: 1.2%)
   - **Affected Package:** lodash 2.4.2
   - **Impact:** Prototype pollution leading to code execution
   - **Remediation:** Upgrade to lodash >= 4.17.12 or use lodash-es alternative

### License Compliance Assessment

**Risky Licenses Identified:**
- **GPL variants:** GPL, GPL-2.0, GPL-3.0 (19 LGPL-3.0 instances) - may impact commercial redistribution
- **Copyleft licenses:** LGPL-2.1, LGPL-3.0 - require source code availability for modifications
- **Permissive but attention-worthy:** BSD variants, MIT (most common, generally safe)

**Compliance Recommendations:**
1. **Audit commercial usage:** GPL/LGPL packages may restrict commercial deployment depending on usage context
2. **Source code availability:** LGPL components require corresponding source code availability
3. **License compatibility:** Ensure MIT/BSD licensed components don't depend on GPL code

### Additional Security Features - Secrets Scanning Results

**Trivy Secrets Scanning Results:**
- **Status:** No secrets detected
- **Coverage:** Scanned debian packages, Node.js packages, and package.json files
- **Scan Targets:** 2,352+ files across container layers
- **Detection Types:** Tested for common secret patterns (API keys, tokens, credentials)

## Task 3 — Toolchain Comparison: Syft+Grype vs Trivy All-in-One

### Accuracy Analysis - Package Detection and Vulnerability Overlap

**Package Detection Accuracy:**
- **Common packages:** 1,126 (98.8% overlap)
- **Syft-only packages:** 13 (1.1%)
- **Trivy-only packages:** 9 (0.8%)
- **Total unique packages:** 1,148

**Vulnerability Detection Overlap:**
- **Grype CVEs:** 58
- **Trivy CVEs:** 62
- **Common CVEs:** 15 (25.9% overlap)

### Tool Strengths and Weaknesses

**Syft+Grype Strengths:**
- **Superior SBOM quality:** Rich metadata, comprehensive package detection
- **Detailed vulnerability context:** Includes EPSS scores, exploitability metrics

**Syft+Grype Weaknesses:**
- **Operational complexity:** Requires two separate tools and workflows
- **Integration overhead:** More complex CI/CD pipeline integration
- **Resource intensive:** Separate processes for SBOM generation and scanning

**Trivy All-in-One Strengths:**
- **Simplicity:** Single tool for complete SBOM + SCA workflow
- **Broad coverage:** Handles containers, OS packages, and application dependencies
- **Runtime awareness:** Better understanding of container layer relationships
- **CI/CD friendly:** Easier integration into automated pipelines

**Trivy All-in-One Weaknesses:**
- **SBOM detail depth:** Less comprehensive metadata compared to Syft
- **Vulnerability database differences:** May miss some vulnerabilities found by specialized scanners
- **All-in-one compromise:** May not excel in any single area as much as specialized tools

### Use Case Recommendations

**Choose Syft+Grype when:**
- **Compliance-first approach:** Detailed SBOMs required for regulatory compliance
- **Supply chain security focus:** Need comprehensive dependency analysis and metadata
- **Enterprise environments:** Teams that can invest in specialized tooling and workflows

**Choose Trivy when:**
- **Operational efficiency:** Development teams needing simple, integrated security scanning
- **CI/CD integration:** Easy automation in existing pipelines
- **Broad security coverage:** Need for secrets, license, and vulnerability scanning in one tool

### Integration Considerations

**CI/CD Integration:**
- **Trivy:** Easier integration, single Docker command, faster pipeline execution
- **Syft+Grype:** More complex orchestration but provides richer artifacts for compliance

**Automation Overhead:**
- **Trivy:** Lower maintenance, single tool updates, simpler deployment
- **Syft+Grype:** Higher maintenance with two tools, but more flexible for custom workflows

**Operational Aspects:**
- **Performance:** Trivy generally faster for complete scans
- **Storage:** Syft generates more detailed SBOM artifacts (JSON depth)
- **Monitoring:** Separate metrics needed for Syft+Grype toolchain health

