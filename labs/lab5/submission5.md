# Lab 5 Submission — Security Analysis: SAST & DAST of OWASP Juice Shop

## Task 1 — Static Application Security Testing with Semgrep

### SAST Tool Evaluation

Semgrep detected **25 security issues** using the combined *security-audit* and *OWASP Top Ten* rulesets.
Its main advantages include semantic pattern recognition for complex injection flaws, precise file/line reporting, and clear remediation guidance.
Detected vulnerability categories include **SQL injection, XSS, path traversal,** and **cryptographic weaknesses**.

### Critical Vulnerability Highlights

1. **SQL Injection (Critical)** — `/src/routes/login.ts:34`: String concatenation in a Sequelize query allows authentication bypass.
2. **Path Traversal (High)** — `/src/routes/fileServer.ts:33`: Unvalidated user input passed to `res.sendFile()` enables directory traversal.
3. **Hardcoded JWT Secret (High)** — `/src/lib/insecurity.ts:56`: JWT signing uses a hardcoded key instead of secure key management.
4. **XSS in Templates (Medium)** — `/src/frontend/src/app/navbar/navbar.component.html:17`: Unquoted template variables allow script injection.
5. **Open Redirect (Medium)** — `/src/routes/redirect.ts:19`: Redirect endpoint uses user input directly without validation.

---

## Task 2 — Dynamic Application Security Testing with Multiple Tools

### Tool Comparison

* **ZAP**: 16 alerts (backup disclosures, config exposures) — best for deep and comprehensive web app scanning, though slower.
* **Nuclei**: 23 findings (exposures, misconfigurations) — fastest template-based scanner.
* **Nikto**: 14 findings (server leaks, headers) — focused on server-level misconfigurations.
* **SQLmap**: Detected SQL injection exploits — best for database-specific vulnerability testing.

### Tool Strengths

**ZAP:** Extensive coverage, active/passive scanning, detailed risk reports.
**Nuclei:** Rapid CVE detection, large community template base, CI/CD friendly.
**Nikto:** Detects outdated software, misconfigurations, and sensitive disclosures.
**SQLmap:** Automated injection testing, payload generation, and DB fingerprinting.

### DAST Findings

* **ZAP:** Backup file exposure at `/ftp/quarantine - Copy`, revealing sensitive data.
* **Nuclei:** Missing headers (COOP, CSP) increasing XSS and clickjacking risk.
* **Nikto:** ETag inode leaks and `robots.txt` exposure aiding reconnaissance.
* **SQLmap:** SQL injection at `/rest/products/search?q=apple` confirmed via boolean/time-based tests.

---

## Task 3 — Correlation Between SAST and DAST

### SAST vs DAST Insights

**SAST Unique:** Code-level issues — injections, hardcoded secrets, XSS templates, path traversal.
**DAST Unique:** Runtime issues — misconfigurations, data exposure, backup leaks, exploit verification.

**Key Difference:**
SAST identifies **implementation flaws early**, while DAST validates **runtime behavior and environment security**.

---

## Integrated Security Recommendations

**DevSecOps Workflow:**

1. **Development:** Integrate Semgrep in pre-commit/PR checks for injections and crypto flaws.
2. **Staging:** Run ZAP and Nuclei for full web app dynamic testing.
3. **Deployment:** Use Nikto for server validation and SQLmap for database endpoints.
4. **Automation:** Apply SAST quality gates, schedule DAST scans, and continuously monitor with Nuclei.

This layered approach ensures **defense-in-depth** and maintains continuous security across the software development lifecycle.
