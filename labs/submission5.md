# Lab 5 — Security Analysis: SAST & DAST of OWASP Juice Shop

### Environment & Artifacts
- Target: OWASP Juice Shop `bkimminich/juice-shop:v19.0.0` running at `http://localhost:3000`.
- Artifacts generated:
  - `labs/lab5/semgrep/semgrep-results.json` — raw Semgrep JSON results
  - `labs/lab5/semgrep/semgrep-report.txt` — human-readable Semgrep report
  - `labs/lab5/analysis/sast-analysis.txt` — Semgrep findings count
  - `labs/lab5/zap/zap-report.json` — ZAP full-scan JSON report
  - `labs/lab5/nikto/nikto-results.txt` — Nikto output
  - `labs/lab5/sqlmap/` — SQLmap outputs
  - `labs/lab5/nuclei/nuclei-results.json` — Nuclei output (empty / no findings)
  - `labs/lab5/analysis/dast-analysis.txt` — DAST summary (counts)
  - `labs/lab5/analysis/correlation.txt` — SAST/DAST correlation summary

---

## Task 1 — Static Application Security Testing with Semgrep

### SAST Tool Effectiveness
- Tool: **Semgrep** (`p/security-audit`, `p/owasp-top-ten`)
- Scope: scanned all source files in Juice Shop
- Result summary: **25 findings** (`labs/lab5/semgrep/semgrep-results.json`)
- Strengths: fast, pattern-based detection of OWASP Top 10 issues (SQLi, XSS, unsafe `eval`, hardcoded secrets). Highlights file locations but requires triage for false positives.

### Critical Vulnerability Analysis
1. **Sequelize query with string concatenation (potential SQL Injection)**  
   - File: `/src/data/static/codefixes/dbSchemaChallenge_1.ts`  
   - Risk: dynamic concatenation with `criteria` — use parameterized queries.  

2. **Sequelize query in another file (same pattern)**  
   - File: `/src/data/static/codefixes/dbSchemaChallenge_3.ts`  

3. **Use of `eval` with user-controlled data**  
   - File: `/src/data/static/codefixes/dbSchemaChallenge_1.ts`  
   - Risk: arbitrary code execution; avoid `eval`.  

4. **DOM-based XSS risk in video handler**  
   - File: `/src/routes/videoHandler.ts`  
   - Risk: unknown `subs` injected into `<script>` — possible XSS.  

5. **Directory listing enabled**  
   - File: `/src/server.ts`  
   - Risk: may expose sensitive files (backup/configs) if served.

---

## Task 2 — Dynamic Application Security Testing with Multiple Tools

### Tool Comparison
| Tool    | Effectiveness summary |
|---------|----------------------|
| **ZAP** | Broad application coverage, finds backup files, misconfigurations, missing headers, XSS. |
| **Nuclei** | Template-driven scan; effectiveness depends on template coverage. No findings in this run. |
| **Nikto** | Server/config issues: header leaks, accessible directories (`/ftp/`), `robots.txt`). |
| **SQLmap** | Detects SQL injection in parameters; confirmed injection for `q` in `/rest/products/search`. |

### Tool Strengths
- **ZAP:** Crawls web app, detects XSS, backup files, header/config issues.  
- **Nuclei:** Fast template-based scan for known CVEs/misconfigurations.  
- **Nikto:** Finds server misconfigurations and exposed directories/files.  
- **SQLmap:** Deep SQL injection testing and exploit confirmation.

### DAST Findings
- **ZAP:** Backup File Disclosure — accessible backup at `/ftp/quarantine%20-%20Copy`.  
- **Nuclei:** No vulnerabilities detected.  
- **Nikto:** ETag header leakage on `/`, `/ftp/` directory accessible, entry in `robots.txt`.  
- **SQLmap:** Parameter `q` in `/rest/products/search` flagged as injectable.

---

## Task 3 — SAST/DAST Correlation and Security Assessment

#### Findings Overview
According to correlation summary (`labs/lab5/analysis/correlation.txt`):

- **SAST (Semgrep):** 25 findings  
- **ZAP:** 16 findings  
- **Nuclei:** 1 finding: no exploitable vulnerabilities detected in this scan (1 template match, no findings).
- **Nikto:** 14 findings  
- **SQLmap:** confirmed injection (`results-10032025_0910am.csv`)  

### SAST vs DAST Findings
- **SAST (Semgrep)** revealed insecure coding patterns that may lead to vulnerabilities:
  - Unsafe Sequelize queries using string concatenation.
  - Use of `eval` with potentially untrusted input.
  - Potential DOM-based XSS in `videoHandler.ts`.  
- **DAST** tools confirmed several runtime issues:
  - **ZAP:** found backup file disclosure and missing security headers.
  - **Nikto:** identified `/ftp/` directory exposure, ETag leaks, and entries in `robots.txt`.
  - **SQLmap:** confirmed SQL injection in `q` parameter of `/rest/products/search`.  
- **Correlation:** SQL Injection, XSS, information disclosure risks confirmed by both SAST and DAST.

### Integrated Security Recommendations
- **High Priority:**  
  - Parameterize database queries.  
  - Fix `/rest/products/search` endpoint (SQL injection).  
  - Protect/remove backup files and `/ftp/`.  
- **Medium Priority:**  
  - Sanitize inputs for XSS; enable CSP.  
  - Harden HTTP headers (CSP, HSTS, X-Content-Type-Options).  
- **Process:**  
  - Integrate Semgrep in CI for early detection.  
  - Run ZAP/Nikto/Nuclei in staging pipelines.  
  - Use SQLmap for regression testing endpoints with user input.  
  - Automate triage of findings into issue tracking.
