# Submission 5 — SAST & DAST Security Analysis (OWASP Juice Shop v19.0.0)

---
Alexander Rozanov / CBS-02 / al.rozanov@innopolis.university
---

## 1) Scope & Method

1. **SAST (Semgrep)** was executed against the Juice Shop source tracked by git using community security rule packs (OWASP Top 10, security-audit).
2. **DAST (ZAP full scan)** targeted the running app on `:3000`, performing spidering + active scanning.
3. **Nikto** performed a quick server/misconfiguration sweep against the same target.

All artifacts referenced below come from the files you shared:

* `semgrep-report.txt`, `semgrep-results.json`
* `zap-report.json`
* `nikto-results.txt`

---

## 2) SAST Results (Semgrep)

**Run summary (from your Semgrep output):**

* **Findings:** **25** (25 blocking)
* **Rules executed:** **140**
* **Files scanned:** **1014**
* **Skipped:** 8 files > 1.0 MB; 139 files matched `.semgrepignore`
* **Timeouts:** 3 rules on a large/minified JS file (`three.js`)

**Key observations (by category):**

* Potential **SQL Injection** patterns (string-built queries / unsafe concatenation in data-access code).
* Potential **client-side XSS sinks** (unsafe/unsanitized templating patterns, unquoted attribute expressions).
* **Hard-coded secret(s)** indicators (e.g., JWT/keys) flagged by rules geared to secret detection.

> Notes: The scan was limited to files tracked by git; for very large/minified third-party assets, consider excluding or increasing per-rule timeouts to reduce noise.

---

## 3) DAST Results (OWASP ZAP + Nikto)

### 3.1 ZAP Full Scan (against `http://localhost:3000`)

**Crawl coverage:** 134 URLs
**Total alerts raised:** **155**

**Most frequent alert categories** (from your logs/JSON):

* **CORS Misconfiguration [40040]** — **95** instances
* **Backup File Disclosure [10095]** — **31** instances (e.g., under `/ftp/**`, including `.bak/.zip/.tar`)
* **Content-Security-Policy Header Not Set [10038]** — **11** instances
* **Cross-Domain Misconfiguration [10098]** — **11** instances
* **Cross-Domain JavaScript Source File Inclusion [10017]** — **10** instances
* **Timestamp Disclosure [10096]** — **13** instances
* **Bypassing 403 [40038]** — **6** instances
* **Dangerous JS Functions [10110]** — **2** instances

**Scanner limitations observed**

* Multiple **DOM XSS active scans** were **skipped** due to WebDriver/browser startup failures inside the container.
* ZAP failed to write `zap-report.json` initially with `Permission denied` when the output folder wasn’t writable by the container user.

### 3.2 Nikto (quick server/misconfig scan)

* Confirms **relaxed CORS** (`Access-Control-Allow-Origin: *`) on responses.
* Standard files present (e.g., `robots.txt`), some **legacy/weak header** patterns (e.g., deprecated Feature-Policy, missing/lenient X-Frame-Options in places).
* Evidence of **backup/sensitive paths** exposed (e.g., under `/ftp/`).

*(Nuclei: results were not uploaded; section remains pending.)*

---

## 4) Correlation (SAST ↔ DAST) & Assessment

* **SQL Injection:** SAST reported SQLi-prone coding patterns; DAST did **not** confirm a runtime SQLi on the crawled paths. This implies **latent risk** in code paths not reached by the spider (e.g., challenge-only routes or inputs requiring authentication/state).
  **Action:** refactor to parameterized queries / ORM binding, then add targeted tests and re-run DAST on those endpoints.

* **XSS & templating:** SAST flagged unsafe template usage; ZAP did not raise reflected/stored XSS in the explored routes.
  **Action:** sanitize and properly quote variables in templates, avoid unsafe sinks, and deploy a restrictive **CSP**.

* **Headers & exposure:** ZAP and Nikto consistently showed **missing CSP**, **over-permissive CORS**, and **backup/hidden files** reachable over HTTP.
  **Action:** harden headers and remove/deny access to backup artifacts; these are real exploitation amplifiers even without a direct injection bug.

Overall risk posture for a deliberately vulnerable target like Juice Shop: **High exposure** via misconfigurations and asset leakage; **possible injection vectors** in code that require deeper, scenario-driven testing.

---

## 5) Recommendations (Prioritized, Actionable)

1. **Eliminate SQLi patterns:** Replace string-built queries with parameter binding / prepared statements; add tests enforcing parameterization.
2. **Enforce a strict CSP:** Start with `default-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'`; add nonces/hashes for scripts; gradually relax as needed.
3. **Lock down CORS:** Replace `*` with an explicit allow-list of origins; disallow credentials unless strictly required; restrict methods/headers.
4. **Secrets hygiene:** Move JWT/keys from code to environment variables or a proper secret manager (Vault/SOPS/KMS).
5. **Remove/deny backup & hidden files:** Purge `/ftp/**` backups and block common backup extensions via web-server rules; prevent such files from being built/deployed; add CI checks.
6. **CI/CD gates:**

   * Add **Semgrep** to PR checks; fail on **new** HIGH/CRITICAL findings.
   * Add **ZAP baseline** to CI (spider + passive + selective active); publish JSON/HTML artifacts.
   * Track **trend** (finding deltas) to prevent regressions.

---

## 6) Reproduction Runbook (Bash)

> Includes two small fixes: creates writable output dir for ZAP (avoids `Permission denied`) and waits for the app to be ready.

```bash
# Prep workspace
mkdir -p labs/lab5/{semgrep,zap,nikto,nuclei,sqlmap,analysis}

# Run Juice Shop locally
docker run -d --name juice-shop-lab5 -p 3000:3000 bkimminich/juice-shop:v19.0.0
for i in {1..30}; do curl -fsS http://localhost:3000 >/dev/null && break; sleep 2; done

# --- SAST: Semgrep (OWASP Top 10 + security-audit)
git clone https://github.com/juice-shop/juice-shop.git --depth 1 --branch v19.0.0 labs/lab5/semgrep/juice-shop
docker run --rm -v "$PWD/labs/lab5/semgrep/juice-shop":/src -v "$PWD/labs/lab5/semgrep":/out semgrep/semgrep:latest \
  semgrep --config=p/security-audit --config=p/owasp-top-ten --json --output=/out/semgrep-results.json /src
docker run --rm -v "$PWD/labs/lab5/semgrep/juice-shop":/src -v "$PWD/labs/lab5/semgrep":/out semgrep/semgrep:latest \
  semgrep --config=p/security-audit --config=p/owasp-top-ten --text --output=/out/semgrep-report.txt /src

# --- DAST: OWASP ZAP (full scan)
mkdir -p labs/lab5/zap && chmod 777 labs/lab5/zap
docker run --rm --network host -v "$PWD/labs/lab5/zap":/zap/wrk/:rw zaproxy/zap-stable:latest \
  zap-full-scan.py -t http://localhost:3000 -J zap-report.json

# --- DAST: Nikto (quick server/misconfig scan)
mkdir -p labs/lab5/nikto
docker run --rm --network host -v "$PWD/labs/lab5/nikto":/tmp frapsoft/nikto:latest \
  -h http://localhost:3000 -o /tmp/nikto-results.txt

# --- (Optional) Nuclei & SQLmap if you want to extend coverage
# docker run --rm --network host -v "$PWD/labs/lab5/nuclei":/app projectdiscovery/nuclei:latest \
#   -u http://localhost:3000 -jsonl -o /app/nuclei-results.json
# docker run --rm --network host -v "$PWD/labs/lab5/sqlmap":/output parrotsec/sqlmap:latest \
#   -u "http://localhost:3000/rest/products/search?q=apple" --batch --level=3 --risk=2 --threads=5 --output-dir=/output
```
