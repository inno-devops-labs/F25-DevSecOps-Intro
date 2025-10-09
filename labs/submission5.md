# Lab 5 Submission: SAST & DAST Analysis of Juice Shop

## Task 1: Static Application Security Testing (SAST) with Semgrep

### SAST Tool Effectiveness
Semgrep scanned the Juice Shop code with security rules. It found 25 issues in 1014 files. Most problems were about unsafe queries and template usage.

### Main SAST Findings
**Top 5 Issues:**
1. **SQL Injection Risk** — Unsafe query in `dbSchemaChallenge_1.ts` (line 5)
2. **SQL Injection Risk** — Unsafe query in `dbSchemaChallenge_3.ts` (line 11)
3. **SQL Injection Risk** — Unsafe query in `unionSqlInjectionChallenge_1.ts` (line 6)
4. **SQL Injection Risk** — Unsafe query in `unionSqlInjectionChallenge_3.ts` (line 10)
5. **Possible XSS** — Unquoted variable in `navbar.component.html` (line 17)

## Task 2: Dynamic Application Security Testing (DAST) with ZAP, Nuclei, Nikto, SQLmap

### Tool Comparison
All DAST tools were run:
- **ZAP:** Scan failed. **Findings: 0**
- **Nuclei:** Found 20 issues (exposed metrics, known bugs)
- **Nikto:** Found 14 issues (headers, info leaks, config problems)
- **SQLmap:** Found 1 SQL injection (details below)

### Tool Strengths
- **ZAP:** Good for finding login/session issues and XSS (when working)
- **Nuclei:** Fast at spotting known bugs and exposures
- **Nikto:** Finds server config problems and info leaks
- **SQLmap:** Best for finding SQL injection

### DAST Findings (Main Example from Each Tool)
- **Nuclei:** Found exposed Prometheus metrics (`/metrics`)
- **Nikto:** Found uncommon headers and open directories from robots.txt
- **SQLmap:** Confirmed SQL injection in `/rest/products/search?q=apple` (parameter `q`, Boolean-based blind)
- **ZAP:** No findings (scan failed)

## Task 3: SAST/DAST Correlation and Security Assessment

### SAST vs DAST Findings
- **SAST (Semgrep):** 25 code issues (mainly SQL injection, template problems)
- **DAST (Nuclei, Nikto, SQLmap):** Nuclei: 20 exposures, Nikto: 14 issues, SQLmap: confirmed SQL injection. ZAP: no results.
- **Overlap:** SQL injection found by both SAST and DAST. Other issues (server config, metrics) only found by DAST.

### Security Recommendations
- Use SAST early to catch code bugs before release.
- Run DAST often to find runtime and config problems.
- Combine SAST and DAST for full coverage: SAST for code, DAST for deployed app.
- Prioritize remediation of vulnerabilities confirmed by both approaches (e.g., SQL injection in `/rest/products/search`).
- Address DAST-only findings (e.g., exposed metrics, server misconfigurations) to reduce attack surface.

---

