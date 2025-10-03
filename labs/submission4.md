# Lab 4 — SBOM & SCA: Juice Shop v19.0.0

## Environment
- Platform: Windows 11 + **WSL Ubuntu** with Docker Desktop (WSL integration).
- Tools: **Syft**, **Grype**, **Trivy**, `jq`.
- Target image: `bkimminich/juice-shop:v19.0.0`.

---

## Task 1 — SBOM Generation (Syft vs Trivy)

**Generated artifacts**
- Syft (JSON): `labs/lab4/syft/juice-shop-syft-native.json`
- Syft (table): `labs/lab4/syft/juice-shop-syft-table.txt`
- Trivy (JSON, list-all-pkgs): `labs/lab4/trivy/juice-shop-trivy-detailed.json`
- Trivy (table): `labs/lab4/trivy/juice-shop-trivy-table.txt`
- Extracted licenses (Syft): `labs/lab4/syft/juice-shop-licenses.txt`
- SBOM analysis: `labs/lab4/analysis/sbom-analysis.txt`

**Package type distribution (from `sbom-analysis.txt`)**
- **Syft**: `binary: 1`, `deb: 10`, `npm: 1128` → total **1139** components.
- **Trivy**: `Node.js: 1125`, `OS (debian 12.11): 10` → total **1135** components.

**License overview**
- Dominant licenses: **MIT (878)**, **ISC (143)**, **Apache-2.0 (12)**.  
- Also found: **BSD-2/3-Clause**, **LGPL-3.0-only (19)**, **GPL-2.0-only (1)**, **MPL-2.0**, **BlueOak-1.0.0**, **Unlicense**, **WTFPL**.
- Trivy also extracts license info for OS/Node packages (see Task 2 summary).

**Conclusion for Task 1**
- Both tools detect most Node.js dependencies.  
- Differences are due to normalization of names/versions and metadata sources.  
- **Syft**: clean SBOM, rich structure, better for SCA pipelines.  
- **Trivy**: convenient “all-in-one” scan (packages + vulnerabilities + licenses).

---

## Task 2 — SCA (Grype vs Trivy)

**Artifacts**
- **Grype JSON** (via Syft SBOM): `labs/lab4/syft/grype-vuln-results.json` (**empty, 0 B**)
- **Trivy JSON (vuln)**: `labs/lab4/trivy/trivy-vuln-detailed.json`
- **Trivy secrets (table)**: `labs/lab4/trivy/trivy-secrets.txt`
- **Trivy licenses (JSON)**: `labs/lab4/trivy/trivy-licenses.json`
- Summary: `labs/lab4/analysis/vulnerability-analysis.txt`

**Severity breakdown**
- **Grype**: no data (empty JSON).  
- **Trivy**: **8 CRITICAL**, **23 HIGH**, **23 MEDIUM**, **16 LOW**.

**Top-5 critical vulnerabilities (Trivy)**
1. **CVE-2023-46233** — `crypto-js@3.3.0` → update to **4.2.0+**  
   (PBKDF2 weakness)
2. **CVE-2015-9235** — `jsonwebtoken@0.x` → update to **4.2.2+**  
   (signature verification bypass)
3. **CVE-2019-10744** — `lodash@2.4.2` → update to **4.17.12+**
4. **CVE-2023-32314** — `vm2@3.9.17` → update to **3.9.18** (sandbox escape)
5. **GHSA-5mrr-rgp6-x4gr** — `marsdb@0.6.11` (command injection) → remove/replace package

> Total unique vulnerabilities (Trivy): **62**.

**License compliance (summary)**
- Unique license types:
  - **Syft**: **31**
  - **Trivy**: **28**
- Risks: copyleft licenses (**GPL-2.0-only**, **LGPL-3.0-only**) require review for compatibility with redistribution; unusual licenses (**BlueOak-1.0.0**, **WTFPL**) may need legal attention.

**Secrets scanning (Trivy)**
- Detected **1 finding per file** in:
  - `/juice-shop/build/lib/insecurity.js`
  - `/juice-shop/lib/insecurity.ts`
  - `/juice-shop/frontend/src/app/app.guard.spec.ts`
  - `/juice-shop/frontend/src/app/last-login-ip/last-login-ip.component.spec.ts`  
- Likely low risk (test/utility files). **Manual review required**.

**Note about Grype**
- Grype failed to update its CVE database (`unable to download db`, `database does not exist`).  
- As a result, `grype-vuln-results.json` is empty.  
- Recommended fix:  
  1. Run `grype db update` once inside WSL.  
  2. Mount local cache into container (`-v ~/.cache/grype/db:/home/grype/.cache/grype/db`).  
  3. Or use `--file /tmp/.../grype-vuln-results.json` directly.

---

## Task 3 — Toolchain Comparison (Syft+Grype vs Trivy)

**Package detection comparison**  
(normalized to unique `name@version`)
- Syft unique packages: **1001**  
- Trivy unique packages: **997**  
- **Common:** **988**  
- **Syft-only:** **13**  
- **Trivy-only:** **9**  
Artifacts:  
`labs/lab4/comparison/syft-packages.txt`, `trivy-packages.txt`,  
`common-packages.txt`, `syft-only.txt`, `trivy-only.txt`.

**CVE coverage comparison**
- Grype CVEs: **0** (empty JSON)  
- Trivy CVEs: **62**  
- Overlap: **0**  
Artifacts: `labs/lab4/comparison/grype-cves.txt`, `trivy-cves.txt`, summary — `accuracy-analysis.txt`.

**Overall recommendations**
- **Syft + Grype** → when SBOM-first workflow is needed (SBOM as source of truth).  
- **Trivy** → when you need quick, consolidated scans (SBOM + vuln + secrets + licenses).  
- Best approach: **use both**:  
  - Syft for SBOM generation  
  - Grype for SBOM-based SCA  
  - Trivy for baseline scans (vulnerabilities, secrets, licenses).
