# Lab 4

## vl.kuznetsov@innopolis.univeristy

## Task 1 Comparison of Syft and Trivy

## Package Type Distribution

Syft and Trivy reported a very similar set of ecosystems.

- **Syft** detected `deb`, `npm`, and additionally a `binary` type (1 package) not seen in Trivy.
- **Trivy** uses slightly different naming conventions: for example, `debian 12.11` instead of `deb`, and `Node.js`
  instead of `npm`.

Total number of discovered packages:

- Syft: 1001
- Trivy: 997

**Conclusion:** Both tools cover the same ecosystems, but Syft provided a bit more detail by including the `binary`
type.

---

## Dependency Discovery Analysis

Total packages identified:

- Syft: 1 binary; 10 dev; 1128 npm
- Trivy: 1.125 node.js; 10 Debian

**Conclusion:** In terms of raw package count Syft found more. For dependency traceability and
completeness, Trivy is more informative.

---

## License Discovery Analysis

- **Syft** aggregates all license data into a single list, often normalized to SPDX identifiers.
- **Trivy** separates results by ecosystem, reporting licenses for OS-level packages and Node.js packages independently.

**Conclusion:** **🔢 (Syft/Trivy)** discovered a wider variety of unique licenses, but the other tool provided a clearer
structure by splitting licenses per ecosystem.

---

## Task 2

### SCA Tool comparison

Grype:

    1 Low
    8 Critical
    12 Negligible
    21 High
    23 Medium

Trivy:

    8 CRITICAL
    23 HIGH
    16 LOW
    23 MEDIUM

Top 5:
`crypto-js@3.3.0 - GHSA-xwcq-pm8m-c4vf | Fix: 4.2.0`

    `jsonwebtoken@0.1.0 - GHSA-c7hr-j4mj-j2w6 | Fix: 4.2.2`

    `jsonwebtoken@0.4.0 - GHSA-c7hr-j4mj-j2w6 | Fix: 4.2.2`

    `lodash@2.4.2 - GHSA-jf85-cpcp-j695 | Fix: 4.17.12`

    `marsdb@0.6.11 - GHSA-5mrr-rgp6-x4gr | Fix:` 

### License Compliance Assessment

According to the Trivy license scan, most packages are under permissive licenses such as **MIT**, **Apache-2.0**, or *
*BSD** (all marked as LOW severity).  
However, several licenses were flagged with higher risk levels:

- **CRITICAL:** WTFPL
- **HIGH:** GPL-1.0-only, GPL-1.0-or-later, GPL-2.0-only, GPL-2.0-or-later, GPL-3.0-only, LGPL-2.0-or-later,
  LGPL-2.1-only, LGPL-3.0-only
- **MEDIUM:** MPL-2.0
- **UNKNOWN:** BlueOak-1.0.0, GFDL-1.2-only, MIT/X11, public-domain, ad-hoc

**Observations:**

- GPL and LGPL family licenses may impose strong copyleft obligations (e.g., requirement to publish source code if the
  software is redistributed).
- WTFPL, despite being permissive, is flagged as CRITICAL because of legal uncertainty.
- UNKNOWN licenses need manual review to ensure compliance.

**Recommendations:**

- Review all GPL/LGPL dependencies and confirm they align with the project’s distribution and compliance strategy.
- Consider replacing or carefully managing packages with **WTFPL** or **UNKNOWN** licenses.
- Maintain an allowlist of approved licenses for future CI/CD scans to avoid compliance risks.

## Task 3

## Task 3 — Toolchain Comparison: Syft+Grype vs Trivy All-in-One

### Accuracy Analysis

**Package Detection:**

- Common packages: 988
- Unique to Syft: 13
- Unique to Trivy: 9

**Vulnerability Detection:**

- CVEs found by Grype: 58
- CVEs found by Trivy: 62
- Common CVEs: 15

**Observation:**  
Both tools largely agree on package detection, with only minor differences (unique packages in each). However, CVE
overlap is relatively small, meaning that each tool catches issues the other one misses.

---

### Tool Strengths and Weaknesses

**Syft + Grype strengths:**

- More precise package detection (including extra package types).
- Provides remediation info (`fix` field) for vulnerabilities.
- EPSS scoring (exploit probability) helps prioritize fixes.
- Better for license discovery (detailed SPDX identifiers).

**Syft + Grype weaknesses:**

- Requires using two separate tools.
- Slightly higher setup and learning curve.

**Trivy strengths:**

- All-in-one solution (SBOM, vulnerabilities, licenses, secrets).
- Simpler integration into CI/CD pipelines.
- Detects secrets and configuration issues in addition to CVEs.

**Trivy weaknesses:**

- No remediation info in vulnerability reports.
- More “noise” due to additional low-severity findings.
- Slightly less detailed package classification.

---

### Use Case Recommendations

- **Use Syft + Grype** when compliance and remediation are the priority — e.g. in enterprise environments, regulated
  industries, or when teams need detailed license tracking and clear patch guidance.
- **Use Trivy** when simplicity and speed matter — e.g. for developers, startups, or continuous integration pipelines
  where a single tool is easier to maintain.

---

### Integration Considerations

Both tools run in Docker and output JSON, making them script-friendly.

- **Syft + Grype:** better suited for environments that can handle multiple tools and need detailed audit trails.
- **Trivy:** lower maintenance burden, faster onboarding, easier automation.

**Conclusion:**  
Using both together may provide the broadest coverage, but in practice, choice depends on the balance between **depth (
Syft+Grype)** and **simplicity (Trivy)**.
