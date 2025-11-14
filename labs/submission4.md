## Lab 4 — SBOM & SCA Submission (OWASP Juice Shop v19.0.0)

### Task 1 — SBOM Generation and Analysis (Syft vs Trivy)

- **Package type distribution**
  - Syft package counts (from `analysis/sbom-analysis.txt`):
    - binary: 1
    - deb: 10
    - npm: 1128
  - Trivy package counts (from `analysis/sbom-analysis.txt`):
    - debian target entries: 10 (unknown type)
    - Node.js packages: 1125 (unknown type)
  - **Conclusion**: Both tools report a very similar npm universe (Syft 1128 vs Trivy 1125). Syft presents explicit types per artifact; Trivy’s JSON aggregates packages under per-target `Results`, which I counted by combining target and type.

- **Dependency discovery analysis**
  - Common packages across tools: 1126
  - Only Syft detected: 13 packages
  - Only Trivy detected: 9 packages
  - Source: `comparison/accuracy-analysis.txt`
  - **Conclusion**: High overlap with small, explainable discrepancies. Differences likely come from metadata parsing, transitive dependency resolution nuances, and version normalization. For strict inventorying, cross-checking both outputs reduces blind spots.

- **License discovery analysis**
  - Unique license families identified:
    - Syft: 31
    - Trivy: 28
    - Source: `analysis/vulnerability-analysis.txt` (License Analysis Summary)
  - Representative findings (from `analysis/sbom-analysis.txt`):
    - Widely seen permissive licenses: MIT (Syft 888; Trivy Node 878), ISC (143 both), Apache-2.0, BSD-2/3-Clause.
    - Copyleft and potentially risky: GPL-2.0/3.0, LGPL-2.1/3.0-only/or-later.
    - Odd/ambiguous: ad-hoc, public-domain, WTFPL.
  - **Conclusion**: Syft surfaced slightly more distinct license labels across the full SBOM, while Trivy’s per-ecosystem views align closely for Node.js. For enforcement, consolidate by SPDX IDs and apply policy per family (permissive vs copyleft).

---

### Task 2 — Software Composition Analysis (Grype vs Trivy)

- **Vulnerability counts by severity** (from `analysis/vulnerability-analysis.txt`):
  - Grype: Critical 8, High 21, Medium 23, Low 1, Negligible 12
  - Trivy: CRITICAL 8, HIGH 23, MEDIUM 23, LOW 16
  - **Conclusion**: Comparable critical/medium totals with some variance in high/low classification. Use both for corroboration on high-impact items.

- **Top 5 critical findings and remediation** (prioritized by severity/EPSS; from `syft/grype-vuln-table.txt`):
  1) vm2 3.9.17 — GHSA-whpj-8f3w-67p5 (Critical)
     - Fix: upgrade to vm2 ≥ 3.9.18
  2) jsonwebtoken 0.1.0 / 0.4.0 — GHSA-c7hr-j4mj-j2w6 (Critical)
     - Fix: upgrade to jsonwebtoken ≥ 4.2.2 (recommended: current 9.x)
  3) vm2 3.9.17 — GHSA-g644-9gfx-q4q4 (Critical)
     - Fix: upgrade vm2 to the latest maintained secure release (≥ 3.9.18)
  4) lodash 2.4.2 — GHSA-jf85-cpcp-j695 (Critical)
     - Fix: upgrade lodash to ≥ 4.17.21
  5) crypto-js 3.3.0 — GHSA-xwcq-pm8m-c4vf (Critical)
     - Fix: upgrade crypto-js to ≥ 4.2.0
  - Note: `marsdb 0.6.11` (Critical, GHSA-5mrr-rgp6-x4gr) shows no fixed version; consider removal, replacement, or vendor patch.

- **License compliance assessment**
  - Coverage: Syft found 31 unique license families vs Trivy 28.
  - Potentially risky copyleft: GPL-1.0/2.0/3.0-only/-or-later; LGPL-2.0/2.1/3.0.
  - Ambiguous/edge cases: ad-hoc, public-domain, WTFPL; verify provenance and policy compatibility.
  - Recommendations:
    - Define policy gates by SPDX license families (block strong copyleft in proprietary distributions; require notices/attribution where applicable).
    - Track license via SBOM ingestion in CI; fail on policy violations; produce attribution files at release.

- **Additional security features (Trivy)**
  - Secrets scanning (from `trivy/trivy-secrets.txt`): No actionable secrets reported in the provided results.
  - License scanning (from `trivy/trivy-licenses.json`): aligned with license counts above; integrate with allow/deny lists.

---

### Task 3 — Toolchain Comparison (Syft+Grype vs Trivy)

- **Accuracy analysis** (from `comparison/accuracy-analysis.txt`):
  - Package overlap: common 1126; Syft-only 13; Trivy-only 9.
  - Vulnerability overlap: Grype CVEs 58; Trivy CVEs 62; common CVEs 15.
  - **Interpretation**: Results are directionally consistent but not identical. Differences stem from SBOM modeling, ecosystem analyzers, and advisory sources. Cross-referencing improves confidence for critical items.

- **Strengths and weaknesses**
  - Syft+Grype
    - Strengths: rich SBOM detail; strong license surfacing; flexible SBOM-first workflows; good alignment with container and language ecosystems.
    - Weaknesses: two-tool integration to manage; vulnerability coverage differs from Trivy; requires SBOM generation or live scan configuration.
  - Trivy (all-in-one)
    - Strengths: single binary/container for SBOM, vulns, secrets, and licenses; simple UX; broad ecosystem support; fast to adopt in CI.
    - Weaknesses: some package/license edge-cases differ from Syft; results organized per target can need post-processing for global counts.

- **Use case recommendations**
  - Fast CI onboarding, unified scanning (SBOM+Vulns+Secrets+Licenses): choose Trivy.
  - SBOM-centric pipelines, deeper license analytics, and flexible artifact formats: choose Syft (+ Grype for vulns).
  - For release governance of high-risk apps, run both; alert on union of critical vulns and consolidate license policy checks.

- **Integration considerations**
  - CI/CD: containerized execution for reproducibility; mount Docker socket only when needed; pin image versions.
  - Outputs: emit JSON SBOMs and JSON vuln reports; archive as build artifacts; diff findings between builds.
  - Policy: implement severity gates (e.g., fail on Critical/High), license allowlist enforcement, and secrets deny-by-default.

---

### Appendix — Artifacts Referenced

- `labs/lab4/syft/juice-shop-syft-native.json`
- `labs/lab4/syft/juice-shop-syft-table.txt`
- `labs/lab4/syft/grype-vuln-results.json`
- `labs/lab4/syft/grype-vuln-table.txt`
- `labs/lab4/trivy/juice-shop-trivy-detailed.json`
- `labs/lab4/trivy/juice-shop-trivy-table.txt`
- `labs/lab4/trivy/trivy-vuln-detailed.json`
- `labs/lab4/trivy/trivy-secrets.txt`
- `labs/lab4/trivy/trivy-licenses.json`
- `labs/lab4/analysis/sbom-analysis.txt`
- `labs/lab4/analysis/vulnerability-analysis.txt`
- `labs/lab4/comparison/accuracy-analysis.txt`


