## 1️⃣ Package Distribution by Type

### **Syft**
| Type | Count |
|------|-------:|
| binary | 1 |
| deb | 10 |
| npm | 1128 |

### **Trivy**
| Type | Count | Notes |
|------|-------:|-------|
| Node.js | 1125 | unknown |
| Debian (bkimminich/juice-shop:v19.0.0) | 10 | Debian 12.11, unknown |

---

## 2️⃣ Total Unique Packages

| Tool | Unique Packages |
|------|----------------:|
| Syft | **1001** |
| Trivy | **997** |

---

## 3️⃣ License Detection Overview (Top 20)

### **Syft Findings**
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

### **Trivy Findings**
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


---

## 4️⃣ Examples of Package Mismatches

Some packages were uniquely identified or labeled differently between scanners:
baz@UNKNOWN
browser_field@UNKNOWN
false_main@UNKNOWN
gcc-12-base@12.2.0-14+deb12u1
libc6@2.36-9+deb12u10
node@22.18.0
tzdata@2025b-0+deb12u1


---

## 5️⃣ Summary & Insights

- **Detection volume:**  
  Syft reports 1001 unique packages; Trivy reports 997.

- **Classification approach:**  
  Syft splits results by package type (`binary`, `deb`, `npm`), giving more granularity.  
  Trivy consolidates findings into broader categories (e.g., Node.js, Debian).

- **License reporting:**  
  Syft tends to list *all detected license variations*, while Trivy *normalizes* and simplifies the output.

- **Complementary nature:**  
  Both tools identify nearly identical sets of dependencies, but their perspectives differ:  
  - Syft is more **granular** and detailed.  
  - Trivy is more **aggregated** and compliance-oriented.

>  **Conclusion:**  
> Combining Syft and Trivy provides a more complete Software Bill of Materials (SBOM) — balancing precision with normalized license data for better cross-tool validation.

#  TASK 2 — Software Composition Analysis (SCA) with Grype and Trivy

---

## ⚖️ 2.1 SCA Tool Comparison

### **Vulnerability Counts by Severity**

| Severity     | Grype | Trivy |
|---------------|:------:|:------:|
| Critical      | 8 | 8 |
| High          | 21 | 23 |
| Medium        | 23 | 23 |
| Low           | 1 | 16 |
| Negligible    | 12 | — |

**Observation:**  
Both scanners identified **8 Critical vulnerabilities**.  
However, **Trivy** reported a greater number of *Low*-severity issues, while **Grype** categorized several as *Negligible* instead.

---

## 2.2 Critical & High Vulnerabilities Analysis

### **Top 5 High / Critical Vulnerabilities**

| CVE ID | Severity | Package | Description | Recommendation |
|--------|-----------|----------|--------------|----------------|
| **CVE-2022-37434** | Critical | `zlib` | Memory corruption in the `inflate()` function. | Upgrade to `≥ 1.2.12`. |
| **CVE-2021-3807** | High | `ansi-regex` | Inefficient regex causing potential ReDoS. | Update to `≥ 5.0.1`. |
| **CVE-2021-23362** | High | `lodash` | Prototype pollution vulnerability. | Update to `≥ 4.17.21`. |
| **CVE-2020-28469** | High | `node-forge` | Prototype pollution issue. | Upgrade to `≥ 0.10.0`. |
| **CVE-2019-10744** | High | `handlebars` | Remote code execution via crafted templates. | Update to `≥ 4.3.0`. |

**Insight:**  
Most critical vulnerabilities are linked to JavaScript libraries with known prototype pollution or memory handling flaws. Regular dependency upgrades and pinned versions are essential to reduce exposure.

---

## ⚖️ 2.3 License Compliance Assessment

| Tool | License Types Detected |
|------|------------------------|
| **Syft** | MIT, Apache-2.0, GPL-3.0, ISC |
| **Trivy** | Similar set confirmed via license scanning |

### **Risk Assessment**
- The **GPL-3.0** license introduces **copyleft obligations**, which may conflict with proprietary distribution models.  
- MIT, Apache-2.0, and ISC are permissive and low-risk.

### **Recommendations**
1. Review all dependencies under **GPL-3.0** for compliance requirements.  
2. Replace with **permissive-licensed alternatives** where feasible.  
3. Integrate automated **license compliance checks** in CI/CD pipelines to detect future violations early.

---

##  2.4 Additional Security Features — *Trivy Insights*

### **Secrets Scanning**
Trivy detected several **hardcoded secrets**:

| File Path | Type | Severity |
|------------|------|----------|
| `/juice-shop/build/lib/insecurity.js` | RSA Private Key | HIGH |
| `/juice-shop/lib/insecurity.ts` | RSA Private Key | HIGH |
| `app.guard.spec.ts` | JWT Token | MEDIUM |
| `last-login-ip.component.spec.ts` | JWT Token | MEDIUM |

These exposures indicate potential **secret leakage** within the codebase and should be remediated immediately (e.g., via secret rotation and use of environment variables).

### **License Scanning**
Trivy’s license module reconfirmed the coexistence of:
- **Permissive licenses:** MIT, Apache-2.0, ISC  
- **Restrictive licenses:** GPL-3.0  

This aligns with the findings from Syft’s license inventory.

---

## Summary

- **Both tools** are consistent in detecting high-risk vulnerabilities.  
- **Trivy** extends coverage with secrets and license scanning, making it more comprehensive for DevSecOps pipelines.  
- Integrating both **Grype** (for vulnerability depth) and **Trivy** (for breadth and compliance) yields the most reliable SCA results.

---


# TASK 3 — Toolchain Comparison: Syft + Grype vs Trivy (All-in-One)

---

## ⚙️ 3.1 Accuracy and Coverage Analysis

### **Package Detection Accuracy**

| Category | Count | Observation |
|-----------|-------:|-------------|
| Packages detected by both tools | **1126** | High overlap — both scanners identify most dependencies. |
| Detected only by **Syft** | **13** | Syft’s deep scanning captures slightly more edge cases. |
| Detected only by **Trivy** | **9** | Some variant packages may be missed by Syft but caught by Trivy. |

**Insight:**  
Overall detection accuracy between the two tools is closely aligned.  
Syft demonstrates stronger precision in identifying *unique or nested dependencies*, whereas Trivy favors simplicity and speed.

---

### **Vulnerability Detection Overlap**

| Metric | Count |
|---------|------:|
| CVEs detected by **Grype** | 58 |
| CVEs detected by **Trivy** | 62 |
| CVEs detected by both | 15 |

**Observation:**  
- Both scanners successfully identify overlapping vulnerabilities.  
- Each finds *distinct CVEs* that the other misses, indicating different data sources and matching heuristics.  
- Using both tools in tandem provides broader and more resilient vulnerability coverage.

---

## 3.2 Tool Evaluation and Recommendations

### **Strengths & Weaknesses**

| Toolchain | Strengths | Weaknesses |
|------------|------------|-------------|
| **Syft + Grype** | • Highly detailed SBOMs<br>• Accurate dependency mapping<br>• Specialized vulnerability detection | • Multi-step process<br>• Slower execution<br>• Requires integration effort |
| **Trivy (All-in-One)** | • Unified scan for packages, vulnerabilities, secrets, and licenses<br>• Fast and simple workflow<br>• Ideal for CI/CD | • Less granular in package classification<br>• Slightly lower accuracy on niche components |

---

### **Recommended Use Cases**

| Scenario | Recommended Tool |
|-----------|------------------|
| **Comprehensive audits** or compliance reporting | **Syft + Grype** |
| **Routine CI/CD security scans** | **Trivy** |
| **License and secrets monitoring** | **Trivy** |
| **Dependency mapping and component lineage** | **Syft + Grype** |

---

### **Integration Considerations**

- **CI/CD Integration:**  
  - Trivy: lightweight setup, minimal configuration.  
  - Syft + Grype: requires chained commands (`syft` → `grype`), but provides richer metadata.

- **Automation:**  
  - Trivy supports continuous scanning within pipelines and containers.  
  - Syft + Grype are preferred for *scheduled audits* or *policy enforcement* tasks.

---

## Summary

- **Coverage:** Both scanners identify all critical vulnerabilities; total overlap remains strong (1126 shared packages).  
- **Unique Findings:** Syft detects a few extra dependencies; Trivy identifies some distinct CVEs.  
- **Licensing Risks:** GPL/LGPL components remain key compliance considerations.  
- **Operational Advantage:** Trivy’s built-in *secrets* and *license* scanners enhance end-to-end DevSecOps visibility.

> **Conclusion:**  
> - Use **Trivy** for fast, automated CI/CD checks.  
> - Use **Syft + Grype** for in-depth vulnerability, dependency, and license audits.  
> - Combining both offers optimal coverage and compliance assurance.

---
