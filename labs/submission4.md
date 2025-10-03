# Lab 4

## Task 1

### Package Type Distribution

`sbom-analusis.txt`

Syft Package Counts:
   1 binary
  10 deb
1128 npm

Trivy Package Counts:
  10 bkimminich/juice-shop:v19.0.0 (debian 12.11) - unknown
1125 Node.js - unknown

#### Observation 
* Both tools detected approximately the same number of Node.js dependencies (~1125), which confirms the consistency of the results.
* Syft classified the packages in more detail, explicitly identifying the binary, deb, and npm types.
* Trivy grouped all the OS packages under the bkimminich/juice-shop:v19.0.0 (debian 12.11) image layer, labeling them as unknown without specifying that they are deb.
* Syft provided a more accurate distribution by ecosystem, which makes it easier to analyze the composition of the image.

### Dependency Discovery Analysis

Syft CycloneDX: Fixed the links between npm packages, reflecting the dependency structure within the JavaScript ecosystem.  
 
Trivy CycloneDX: Also exported dependencies, but the lack of accurate classification of system packages (labeled as unknown) made it difficult to interpret the dependency graph at the OS component level.


#### Observation 

* Syft CycloneDX correctly identifies the relationships between npm packages, reflecting the dependency structure within the JavaScript ecosystem.
* Trivy CycloneDX also exports dependencies, but system packages are marked as `unknown`, making it difficult to construct a dependency graph at the OS component level.
* The lack of precise typing in Trivy reduces the transparency of analysis for non-JavaScript components.
* Syft provides a more structured representation of dependencies, which is useful for comprehensive analysis of image composition.

### License Discovery Analysis

* Syft identified a wide range of licenses, including 890 MIT, 143 ISC, 19 LGPL-3.0, and 15 Apache-2.0, as well as less common types such as BSD, GPL, BlueOak, WTFPL, and others.
* Syft's license coverage covers almost all detected components, providing a high level of transparency.
* Trivy for OS packages found licenses of the GPL, LGPL, Artistic, Apache-2.0, and public domain families, but the total number of entries was significantly lower, at only 16.
* Trivy for Node.js packages showed results close to Syft: 880 MIT, 143 ISC, 19 LGPL-3.0-only, and 12 Apache-2.0, with a similar distribution of license types.

#### Observations

* Syft demonstrated a broad license coverage, covering both popular types (MIT, ISC, Apache-2.0) and less common ones (BlueOak, WTFPL), ensuring a high level of transparency across all components.
* Trivy showed limited licenses for OS packages (only 16 entries), despite the presence of diverse types such as GPL, LGPL, Artistic, and public domain.
* For Node.Trivy's js-packages provided results similar to Syft, with a similar distribution of licenses, which confirms the consistency of the JavaScript ecosystem.
* Overall, Syft provides a more detailed and comprehensive representation of license information, especially when analyzing mixed ecosystems.


## Task 2


### SCA Tool Comparison


`vulnerability-analysis.txt`
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


#### Observation

* Both tools identified the same number of critical (8) and medium (23) vulnerabilities, confirming consistency in key risks.
* Trivy found more low-severity vulnerabilities (16 LOW vs. 1 LOW in Grype), which may indicate broader sensitivity to less significant issues.
* Grype additionally classified 12 vulnerabilities as Negligible, which is not present in the Trivy report.



### Critical Vulnerabilities Analysis


| Package          | Version       | Fixed In      | Vulnerability ID                               | Severity | Remediation                                                                                                                            |
| ---------------- | ------------- | ------------- | ---------------------------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| **crypto-js**    | 3.3.0         | 4.2.0         | CVE-2023-46233                                 | CRITICAL | PBKDF2 implementation is weak (SHA1, 1 iteration). **Upgrade to 4.2.0**.                                                                       |
| **jsonwebtoken** | 0.1.0 / 0.4.0 | 4.2.2         | CVE-2015-9235                                  | CRITICAL | Token verification bypass. **Upgrade to ≥4.2.2**.                                                                                              |
| **lodash**       | 2.4.2         | 4.17.12       | CVE-2019-10744                                 | CRITICAL | Prototype pollution. **Upgrade to ≥4.17.12**.                                                                                                  |
| **marsdb**       | 0.6.11        | –             | GHSA-5mrr-rgp6-x4gr                            | CRITICAL | Command injection, **no fix available**. Consider replacing package.                                                                           |
| **vm2**          | 3.9.17        | 3.9.18 / none | CVE-2023-32314, CVE-2023-37466, CVE-2023-37903 | CRITICAL | Multiple sandbox escapes with potential RCE. **Upgrade to ≥3.9.18**, but project is discontinued. Strongly consider removing `vm2` dependency. |



### License Compliance Assessment

Detected unique license types:
  - Syft: 31
  - Trivy: 28

### Additional Security Concerns

**RSA Private Key Exposure**  
  - Embedded RSA private key found in JavaScript file, added via `Docker COPY`.  
  - Present in the final image, which poses a risk of key exposure.

**Hardcoded JWT Token**  
  - A hard-coded JWT token is detected in the test artifact.
- It should not be included in the production image and should be excluded from the final build.

## Task 3

## Comparative Analysis of Syft+Grype vs Trivy

### Accuracy Analysis

**Package Detection**
- Detected by both tools: 1126 packages
- Syft only: 13 packages
- Trivy only: 9 packages

**Vulnerabilities (CVE)**
- Grype found: 58 CVE
- Trivy found: 62 CVE
- Total CVE: 15

Conclusion: Both tools demonstrate a high degree of consistency, especially in detecting key components and vulnerabilities, with minor differences in coverage.


### Tool Strengths and Weaknesses

**Syft + Grype**
- Advantages:
  - SBOM-first approach: support for CycloneDX and SPDX
  - Clear package typing and path specification
  - Ability to re-scan SBOM
  - Suitable for auditing and compliance
- Disadvantages:
  - Two-step process: accuracy depends on the quality of the SBOM

**Trivy**
- Advantages:
  - Universal image scanning: covers OS and applications
  - Additional scanners: secrets, licenses
  - Support for CycloneDX/SPDX
- Disadvantages:
  - Less accurate package typing (`unknown`)
  - Noisy output at Low severity level

---

### Use Case Recommendations

- **For compliance, auditing, and SBOM management**:  
  Use the **Syft → Grype** link

- **For quick and broad security coverage with minimal configuration**:  
  Use **Trivy**

- **For production pipelines** - a combined approach:
  - **Build**: Syft SBOM, Trivy scanning (vulnerabilities, secrets, licenses)
  - **Testing**: Grype as an additional SBOM scanner
  - **Storage**: save SBOM and reports along with image hashes


### Integration Considerations

- **Security policies**: block build on CRITICAL/HIGH, allow exceptions, document Low/Negligible
- **Secrets**: be sure to run Trivy to find secrets
- **Licenses**: use allowlist (MIT, Apache, BSD), mark copyleft (GPL, LGPL) for manual verification
- **Artifacts**: save SBOM (CycloneDX/SPDX), JSON reports from Trivy/Grype, and comparison results; record scanner versions
- **Repeated scans**: regularly re-scan saved SBOMs to identify new CVEs