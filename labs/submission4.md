# Lab 04 Solution

## Task 1 — SBOM Generation with Syft and Trivy 

### Package Type Distribution (Syft vs Trivy)

Accoding to `sbom-analysis.txt`
* **Syft:**
    * 1 `binary`
    * 10 `deb`
    * 1128 `npm`
* **Trivy:**
    * 1125 `Node.js` packages
    * 10 `debian` OS packages

**Observations:**
* Both tools detected ~1125 Node.js dependencies, which aligns closely.
* Syft distinguished package types more granularly (binary, deb, npm).
* Trivy grouped OS packages under the target image layer (bkimminich/juice-shop:v19.0.0 (debian 12.11)), labeling them as unknown type instead of “deb.”
* Syft provides a clearer breakdown of package ecosystems.

### Dependency Discovery Analysis

* **Syft CycloneDX:** Captured `npm` relationships, showing dependencies at the JavaScript ecosystem level.
* **Trivy CycloneDX:** Also exported dependencies, but its `unknown` typing for OS packages made the dependency graph less explicit for system components.

**Observations:**
* Both tools reported similar component counts.
* Syft’s richer type classification and native JSON relationships gave more detail about what kind of package each dependency was.
* For dependency graphs, Syft seemed to provide more structured ecosystem metadata.
* Trivy’s output is still usable for both OS and Node.js dependencies but was flatter in categorization.
### License Discovery Analysis
* **Syft Licenses (summary):**
    * Found 890 MIT, 143 ISC, 19 LGPL-3.0, 15 Apache-2.0, plus smaller counts across BSD, GPL, BlueOak, WTFPL, etc.
    * Wide coverage across all detected components.
* **Trivy Licenses (OS packages):**
    * Detected GPL family, LGPL, Artistic, Apache-2.0, public domain.
    * License reporting was much lighter here (16 total entries).
* **Trivy Licenses (Node.js packages):**
    * Found 880 MIT, 143 ISC, 19 LGPL-3.0-only, 12 Apache-2.0, similar spread to Syft.

**Observations:**
* For Node.js packages, Trivy and Syft produced nearly identical distributions (MIT dominating, then ISC, LGPL, Apache).
* For OS packages, Trivy clearly outperformed Syft — it captured Debian package licenses where Syft only reported them as deb but without full license detail.
* Syft provided the richest total license coverage because it aggregated both OS + Node.js, but Trivy gave a better breakdown of OS-level licensing.

## Task 2 — Software Composition Analysis with Grype and Trivy

### SCA Tool Comparison 

According to `vulnerability-analysis.txt`

* Grype (SBOM-based via Syft):
    * Detected 65 total vulns: 8 Critical, 21 High, 23 Medium, 1 Low, 12 Negligible
    * Output: `syft/grype-vuln-results.json`, `syft/grype-vuln-table.txt`
* Trivy (direct image scan):
    * Detected 70 total vulns: 8 Critical, 23 High, 23 Medium, 16 Low
    * Output: `trivy/trivy-vuln-detailed.json`, plus extras for secrets and licenses.

**Observation:**

Both tools agreed on 8 critical vulnerabilities. Trivy surfaced more Low severity vulns, while Grype provided a more nuanced Negligible category.

### Critical Vulnerabilities Analysis

* Top Critical Findings (with remediation):

| Package          | Version       | Fixed In      | Vulnerability ID                               | Severity | Remediation                                                                                                                            |
| ---------------- | ------------- | ------------- | ---------------------------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| **crypto-js**    | 3.3.0         | 4.2.0         | CVE-2023-46233                                 | CRITICAL | PBKDF2 implementation is weak (SHA1, 1 iteration). **Upgrade to 4.2.0**.                                                                       |
| **jsonwebtoken** | 0.1.0 / 0.4.0 | 4.2.2         | CVE-2015-9235                                  | CRITICAL | Token verification bypass. **Upgrade to ≥4.2.2**.                                                                                              |
| **lodash**       | 2.4.2         | 4.17.12       | CVE-2019-10744                                 | CRITICAL | Prototype pollution. **Upgrade to ≥4.17.12**.                                                                                                  |
| **marsdb**       | 0.6.11        | –             | GHSA-5mrr-rgp6-x4gr                            | CRITICAL | Command injection, **no fix available**. Consider replacing package.                                                                           |
| **vm2**          | 3.9.17        | 3.9.18 / none | CVE-2023-32314, CVE-2023-37466, CVE-2023-37903 | CRITICAL | Multiple sandbox escapes with potential RCE. **Upgrade to ≥3.9.18**, but project is discontinued. Strongly consider removing `vm2` dependency. |


### License Compliance Assessment
**Unique license types found:**
* Syft: 31
* Trivy: 28
### Additional Security Features
* AsymmetricPrivateKey - RSA private key embedded in built JS
    * Added via Docker COPY; present in runtime image.
    * Сopied into image; risk of key disclosure.
* JWT (jwt-token) - Hardcoded JWT token in test
    * Test artifact; should not ship in prod image.

## Task 3 – Toolchain Comparison: Syft+Grype vs Trivy All-in-One

### Accuracy Analysis

**Package Detection Accuracy** (from `accuracy-analysis.txt`)
* Packages detected by both tools: 1126
* Packages only detected by Syft: 13
* Packages only detected by Trivy: 9

**Vulnerability Detection Overlap**
* CVEs found by Grype: 58
* CVEs found by Trivy: 62
* Common CVEs: 15

### Tool Strengths and Weaknesses

**Syft + Grype**
* Strengths: SBOM-first workflow (CycloneDX/SPDX), clear package types & file locations, deterministic re-scans from SBOMs, great for compliance/audit.
* Weaknesses: Two-step pipeline; completeness is only as good as the SBOM generation.
**Trivy**
* Strengths: All-in-one image scan; strong OS+app coverage; extra scanners (secrets, license); can also emit CycloneDX/SPDX.
* Weaknesses: Flatter package typing in detailed JSON (e.g., unknown), slightly noisier at Low severity.

### Use Case Recommendations

* SBOM governance, compliance, reproducibility: choose Syft → Grype.
* Fast, broad security coverage (plus secrets/license) with minimal setup: choose Trivy.
* Production pipelines: run both for best coverage and auditability:
    * Build: generate SBOM with Syft; scan image with Trivy (vulns + secrets + license).
    * Test: scan Syft SBOM with Grype as a second opinion.
    * Store SBOMs and reports with image digests.

### Integration Considerations
* **Gates:** fail on CRITICAL,HIGH; allow policy-based waivers; keep a Negligible/Low posture documented.
* **Secrets:** enforce Trivy secrets scan
* **Licenses:** define an allowlist (MIT/Apache/BSD) and flag copyleft (GPL/LGPL) for review.
* **Artifacts:** persist SBOMs (CycloneDX/SPDX), Trivy/Grype JSONs, and the comparison outputs; pin scanner versions.
* **Re-scans:** periodically re-scan stored SBOMs to catch newly disclosed CVEs.