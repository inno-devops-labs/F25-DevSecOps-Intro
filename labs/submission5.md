# Lab 5 — Security Analysis: SAST & DAST of OWASP Juice Shop

## Task 1 — SAST Analysis (Semgrep)

**Tool Effectiveness:**
Semgrep detected 25 code-level findings, including SQL injections, unquoted template variables, hardcoded credentials, XSS, and unsafe file handling. Provides precise file locations and severity levels, ideal for early-stage DevSecOps integration.

**Critical Findings (Top 5):**

1. **SQL Injection** — `/src/data/static/codefixes/dbSchemaChallenge_1.ts`
   Tainted user input in Sequelize query; use parameterized queries.
2. **SQL Injection** — `/src/data/static/codefixes/dbSchemaChallenge_3.ts`
   Similar vulnerability with template literals.
3. **SQL Injection** — `/src/data/static/codefixes/unionSqlInjectionChallenge_1.ts`
4. **Hardcoded JWT Secret** — `/src/lib/insecurity.ts`
   Secrets in code; move to environment variables or secure vault.
5. **XSS via Unquoted HTML Attributes** — `/src/frontend/src/app/navbar/navbar.component.html`

---

## Task 2 — DAST Analysis (ZAP + Nuclei + Nikto + SQLmap)

**ZAP Findings (16 total, sample):**

* Backup File Disclosure
* Bypassing 403
* CORS Misconfiguration
* Content Security Policy (CSP) Header Not Set

**Nuclei Findings:**

* Public Swagger API exposed at `http://localhost:3000/api-docs/swagger.json` (info severity, CWE-200)

**Nikto Findings:**
* Server leaks inodes via ETags
* Uncommon headers detected: `feature-policy`, `access-control-allow-origin`, `x-frame-options`, `x-content-type-options`
* `/ftp/` in `robots.txt` accessible

**SQLmap Findings:**

* Parameter `q` in `/rest/products/search?q=apple` appears injectable (basic test, see CSV for details)

**Tool Strengths:**

* **ZAP**: Comprehensive coverage of web application runtime issues
* **Nuclei**: Fast template-based CVE scanning
* **Nikto**: Web server misconfigurations
* **SQLmap**: SQL injection detection

---

## Task 3 — SAST/DAST Correlation

**Findings Comparison:**

* **SAST** found 25 code-level issues; **DAST** runtime findings: ZAP 16, Nuclei 22, Nikto 25, SQLmap output in CSV.
* **Overlap:** SQL injection detected by SAST corresponds to potential injection points tested by SQLmap.
* **Unique:** SAST detected hardcoded secrets and unsafe template variables; DAST detected server misconfigurations and API exposures not visible in source code.

**Integrated Recommendations:**

* Use **SAST** early in CI/CD for code-level vulnerabilities.
* Use **DAST** in staging/QA to detect runtime misconfigurations and exposures.
* Correlate findings to prioritize remediation; for example, validate SAST-reported injection points using SQLmap tests.
* Regularly update templates/rules in Nuclei and Semgrep for latest CVEs.

