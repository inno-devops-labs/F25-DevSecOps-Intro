# Submission 4 — SBOM Generation & Software Composition Analysis (OWASP Juice Shop v19.0.0)

---
Alexander Rozanov / CBS-02 / al.rozanov@innopolis.university
---

## Repository & Branch
- Fork: `https://github.com/Rozanalex/F25-DevSecOps-Intro`
- Branch: `feature/lab4`
- Target image: `bkimminich/juice-shop:v19.0.0`
- Working dir: repo root (this file at `labs/submission4.md`)

---

## Task 1 — SBOM Generation & Analysis

### 1.1 SBOMs Produced
- Syft native JSON: `labs/lab4/syft/juice-shop-syft-native.json`
- Trivy detailed JSON (all packages): `labs/lab4/trivy/juice-shop-trivy-detailed.json`

### 1.2 Component Analysis (Package Type Distribution)
**Syft** package types (from native SBOM):
- binary: **1**
- deb: **10**
- npm: **1128**

**Trivy** package type breakdown: not captured in the exported file due to format/output limitations; image packages were enumerated across OS + npm ecosystems.

### 1.3 License Extraction Summary
**Syft (top licenses by frequency)**  
MIT (~888), ISC (~143), LGPL-3.0 (~19), Apache-2.0 (~15), BSD-3-Clause (~14), BSD-2-Clause (~12), BlueOak-1.0.0 (~5), Artistic (~5), GPL-2 (~6), GPL-3 (~4).  
**Trivy** identified ~**28** unique license types across npm and OS packages. One package (`truncate-utf8-bytes`) declares **WTFPL**, which Trivy flags as **CRITICAL/forbidden**.

**Notes for compliance**
- The codebase is predominantly permissive-licensed (MIT/ISC/Apache).  
- Presence of copyleft (GPL/LGPL) requires usage review if the project is distributed in proprietary contexts.  
- Forbidden/controversial licenses (e.g., WTFPL) should be replaced where feasible.

---

## Task 2 — Software Composition Analysis (SCA)

### 2.1 Vulnerabilities by Severity

| severity   | grype | trivy |
|------------|-------|-------|
| CRITICAL   | 8     | 8     |
| HIGH       | 149   | 71    |
| MEDIUM     | 277   | 108   |
| LOW        | 107   | 373   |
| NEGLIGIBLE | 5     | —     |
| UNKNOWN    | —     | 3     |

### 2.2 Top Critical Findings & Remediation

1) **CVE-2015-9235 — jsonwebtoken (npm)**  
   *Impact:* verification bypass (alg=none/HS* confusion).  
   *Observed version:* `jsonwebtoken@0.1.0` (also transitive variants).  
   *Fix:* **>= 4.2.2**.  
   *Action:* bump direct and transitive JWT libs (`jsonwebtoken`, `jws`, `jwa`, `express-jwt`) to non-vulnerable ranges; re-run tests.

2) **Embedded RSA Private Key (secret) — `/juice-shop/lib/insecurity.ts`**  
   *Impact:* hard-coded private key in image.  
   *Fix:* remove from repo/build context; load keys from secrets at runtime; ensure tests use placeholders.

3) **JWT tokens in test fixtures — Angular specs**  
   *Impact:* test JWT values baked into image layers.  
   *Fix:* redact fixtures or load from env during tests; exclude from production image.

4) **OS / npm legacy crypto handling (related HIGHs around `jws`)**  
   *Impact:* forgeable tokens before `jws@3.0.0`.  
   *Fix:* upgrade `jws` **>= 3.0.0** and any framework plugins depending on old JWT stack.

5) **Problematic license: WTFPL (policy risk)**  
   *Impact:* policy violation in many orgs; Trivy marks as CRITICAL (forbidden).  
   *Fix:* replace `truncate-utf8-bytes` or vendor a permissive alternative.

> After upgrades and secret removal, re-scan to ensure CRITICAL/HIGH counts drop and license/secrets checks pass.

### 2.3 Secrets & Sensitive Artifacts (from image)
- **Asymmetric Private Key** in `lib/insecurity.ts` (HIGH).  
- **JWT tokens** present in Angular test files (`app.guard.spec.ts`, `last-login-ip.component.spec.ts`) (MEDIUM).  
**Remediation:** strip from build context, or ensure tests are excluded in production build; manage secrets via CI/CD secret stores.

---

## Task 3 — Toolchain Comparison (Syft+Grype vs. Trivy)

### 3.1 Accuracy & Coverage (package & CVE overlap)

| metric               | value |
|----------------------|-------|
| Common packages      | 0     |
| Syft-only packages   | 1139  |
| Trivy-only packages  | 1135  |
| CVEs (Grype)         | 546   |
| CVEs (Trivy)         | 190   |
| Common CVEs          | 62    |

**Interpretation**
- Package schemas differ (namespaces/normalization), hence zero direct package string overlaps, while CVE overlap exists (62).  
- Both tools reported **8 CRITICAL**; cross-validation reduces false negatives.

### 3.2 Summary & When to Use
- **Syft + Grype**: reproducible SBOMs, strong SCA off SBOMs; good for SBOM-first workflows and supply-chain attestations.  
- **Trivy**: one tool for SBOM + SCA + **secrets** + **licenses**; great for fast CI gates and policy checks.

### 3.3 Action Plan (prioritized)
1. Remove embedded **private key** and **test JWTs** from the image build.  
2. Upgrade **JWT stack** (`jsonwebtoken` >= 4.2.2, `jws` >= 3.0.0) and other flagged CRITICAL/HIGH deps.  
3. Replace packages with **WTFPL** or incompatible licenses.  
4. Add CI jobs for both scanners; fail on *new* CRITICAL/HIGH and on forbidden licenses/secrets.

---

## Reproduction (minimal)

```bash
# Pull tools
docker pull anchore/syft:latest
docker pull anchore/grype:latest
docker pull aquasec/trivy:latest

# SBOMs
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$PWD":/out anchore/syft:latest \
  bkimminich/juice-shop:v19.0.0 -o syft-json=/out/labs/lab4/syft/juice-shop-syft-native.json

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$PWD":/out aquasec/trivy:latest image \
  --format json --output /out/labs/lab4/trivy/juice-shop-trivy-detailed.json --list-all-pkgs \
  bkimminich/juice-shop:v19.0.0

# SCA
docker run --rm -v "$PWD":/out anchore/grype:latest \
  sbom:/out/labs/lab4/syft/juice-shop-syft-native.json -o json > labs/lab4/syft/grype-vuln-results.json

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$PWD":/out aquasec/trivy:latest image \
  --format json --output /out/labs/lab4/trivy/trivy-vuln-detailed.json \
  bkimminich/juice-shop:v19.0.0

# Licenses & Secrets (Trivy)
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$PWD":/out aquasec/trivy:latest image \
  --scanners license --format json --output /out/labs/lab4/trivy/trivy-licenses.json \
  bkimminich/juice-shop:v19.0.0

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$PWD":/out aquasec/trivy:latest image \
  --scanners secret --format table --output /out/labs/lab4/trivy/trivy-secrets.txt \
  bkimminich/juice-shop:v19.0.0