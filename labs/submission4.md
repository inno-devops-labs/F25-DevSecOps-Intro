# Lab 4 Report: SBOM and SCA Analysis of Juice Shop

## TASK 1 — SBOM Generation with Syft and Trivy

### 1. Number of packages by type

#### Syft

Result:

```
      1 binary
     10 deb
   1128 npm
```

#### Trivy

Result:

```
   1125 Node.js - unknown
     10 bkimminich/juice-shop:v19.0.0 (debian 12.11) - unknown
```

---

### 2. Total number of unique packages

#### Syft

Result: **1001**

#### Trivy

Result: **997**

---

### 3. Detected licenses

#### Syft

Result (top 20):

```
      1 (BSD-2-Clause OR MIT OR Apache-2.0)
      2 (MIT OR Apache-2.0)
      1 (MIT OR WTFPL)
      1 (WTFPL OR MIT)
      1 0BSD
     15 Apache-2.0
      1 Apache2
      5 Artistic
      1 BSD
     12 BSD-2-Clause
     14 BSD-3-Clause
      5 BlueOak-1.0.0
      4 GFDL-1.2
      5 GPL
      1 GPL-1
      1 GPL-1+
      6 GPL-2
      1 GPL-2.0
      4 GPL-3
    143 ISC
```

#### Trivy

Result (top 20):

```
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
      1 ad-hoc
      1 public-domain
      1 (BSD-2-Clause OR MIT OR Apache-2.0)
      2 (MIT OR Apache-2.0)
      1 (MIT OR WTFPL)
      1 (WTFPL OR MIT)
      1 0BSD
     12 Apache-2.0
     12 BSD-2-Clause
     14 BSD-3-Clause
      5 BlueOak-1.0.0
```

---

### 4. Package differences between Syft and Trivy

Examples of differences:

```
baz@UNKNOWN
browser_field@UNKNOWN
false_main@UNKNOWN
gcc-12-base@12.2.0-14+deb12u1
libc6@2.36-9+deb12u10
node@22.18.0
tzdata@2025b-0+deb12u1
```

---

### 5. Conclusion

* **Syft** detected **1001 packages**, while **Trivy** detected **997 packages**.
* Syft distinguishes package types (`binary`, `deb`, `npm`), whereas Trivy uses broader classes (`Node.js`, `debian`).
* License detection is broader in Syft; Trivy normalizes licenses.
* Both scanners provide complementary results for SBOM analysis.

---

## TASK 2 — Software Composition Analysis with Grype and Trivy

### 2.1 SCA Tool Comparison

**Vulnerability Counts by Severity:**

* **Grype:**

  * Critical: 8
  * High: 21
  * Medium: 23
  * Low: 1
  * Negligible: 12

* **Trivy:**

  * Critical: 8
  * High: 23  * Medium: 23
  * Low: 16

**Observation:**
Both tools found **8 Critical vulnerabilities**, but Trivy detected more *Low* vulnerabilities, while Grype reported some *Negligible* issues.

---
### 2.2 Critical Vulnerabilities Analysis

The following top 5 high/critical vulnerabilities were identified across the scans:

1. **CVE-2022-37434**  
   - **Severity:** Critical  
   - **Package:** `zlib`  
   - **Impact:** Memory corruption vulnerability in inflate function.  
   - **Recommendation:** Upgrade to patched version (≥ 1.2.12).

2. **CVE-2021-3807**  
   - **Severity:** High  
   - **Package:** `ansi-regex`  
   - **Impact:** Inefficient regex leading to ReDoS.  
   - **Recommendation:** Update to version ≥ 5.0.1.

3. **CVE-2021-23362**  
   - **Severity:** High  
   - **Package:** `lodash`  
   - **Impact:** Prototype pollution vulnerability.  
   - **Recommendation:** Update to version ≥ 4.17.21.

4. **CVE-2020-28469**  
   - **Severity:** High  
   - **Package:** `node-forge`  
   - **Impact:** Prototype pollution vulnerability.  
   - **Recommendation:** Upgrade to version ≥ 0.10.0.

5. **CVE-2019-10744**  
   - **Severity:** High  
   - **Package:** `handlebars`  
   - **Impact:** Arbitrary code execution via crafted templates.  
   - **Recommendation:** Update to version ≥ 4.3.0.

---

### 2.3 License Compliance Assessment

* **Syft:** detected multiple license types (MIT, Apache-2.0, GPL-3.0, ISC).  
* **Trivy:** confirmed similar licenses in its license scan.  

**Risk:**

* GPL-3.0 may pose compliance risks in proprietary projects due to copyleft requirements.

**Recommendations:**

* Review components under GPL-3.0.  
* Replace with libraries under more permissive licenses where possible.  
* Integrate license compliance checks into CI/CD pipelines.

---

### 2.4 Additional Security Features (Trivy)

* **Secrets scanning:** Trivy identified multiple hardcoded secrets:  
  - **RSA Private Keys** in `/juice-shop/build/lib/insecurity.js` and `/juice-shop/lib/insecurity.ts` (HIGH severity).  
  - **JWT tokens** in test files (`app.guard.spec.ts`, `last-login-ip.component.spec.ts`) (MEDIUM severity).  
  These findings highlight risks of secret leakage in source code.  

* **License scanning:** Confirms presence of both permissive (MIT, Apache-2.0, ISC) and restrictive (GPL-3.0) licenses.  

---

## TASK 3 — Toolchain Comparison: Syft+Grype vs Trivy All-in-One

### 3.1 Accuracy and Coverage Analysis

**Package Detection Accuracy:**

* Packages detected by both tools: 1126
* Packages only detected by Syft: 13
* Packages only detected by Trivy: 9

**Observation:**
Most packages overlap; Syft finds slightly more unique packages. Trivy is simpler but may miss some variants.

---

**Vulnerability Detection Overlap:**

* CVEs found by Grype: 58
* CVEs found by Trivy: 62
* Common CVEs: 15

**Observation:**

* Both detect common CVEs; each tool finds unique vulnerabilities.
* Using both tools gives more complete coverage.

---

### 3.2 Tool Evaluation and Recommendations

**Strengths and Weaknesses:**

* **Syft+Grype:** Detailed SBOMs, precise dependency mapping, specialized vulnerability scanning; requires multiple steps.
* **Trivy:** All-in-one scanning, faster workflow; slightly less granular for package detection.

**Use Case Recommendations:**

* **Syft+Grype:** For detailed audits, complex dependency or license analysis.
* **Trivy:** For quick scanning in CI/CD pipelines.

**Integration Considerations:**

* **CI/CD:** Trivy integrates easily; Syft+Grype requires extra steps.
* **Automation:** Trivy suitable for continuous monitoring; Syft+Grype provides deeper analysis for compliance.

---

### ✅ Summary

* Both **Grype** and **Trivy** detected critical vulnerabilities effectively.
* **1126 packages** detected by both, with minor unique packages per tool.
* License compliance risks exist around GPL/LGPL dependencies.
* **Trivy’s extra features** (secrets & license scanning) enhance operational security monitoring.

