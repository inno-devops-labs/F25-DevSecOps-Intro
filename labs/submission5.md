## 🔍 TASK 4 — Static Application Security Testing (SAST) with Semgrep

---

### SAST Tool Effectiveness

| Parameter | Details |
|------------|----------|
| **Tool** | **Semgrep** (`p/security-audit`, `p/owasp-top-ten`) |
| **Scope** | Full source code scan of the *Juice Shop* application |
| **Findings** | **25 total** (`labs/lab5/semgrep/semgrep-results.json`) |
| **Strengths** | Fast, rule-based scanning engine targeting OWASP Top 10 vulnerabilities (e.g., SQL Injection, XSS, unsafe `eval`, hardcoded secrets). Identifies specific file paths and code locations. |
| **Limitations** | Requires manual triage — false positives possible, especially for dynamic code paths and framework-specific patterns. |

---

### Critical Vulnerability Analysis (Top 5 Findings)

| # | Vulnerability | File | Risk Description | Recommended Mitigation |
|---|----------------|------|------------------|-------------------------|
| **1** | SQL Injection via string concatenation in Sequelize query | `/src/data/static/codefixes/dbSchemaChallenge_1.ts` | Dynamic query construction using `criteria` input allows injection. | Replace with **parameterized queries** or query bindings. |
| **2** | Repeated Sequelize concatenation issue | `/src/data/static/codefixes/dbSchemaChallenge_3.ts` | Same pattern as above, repeated unsafe concatenation. | Apply the same **parameterization fix**. |
| **3** | Unsafe use of `eval` with user input | `/src/data/static/codefixes/dbSchemaChallenge_1.ts` | Direct execution of user-supplied code can lead to **RCE (Remote Code Execution)**. | Refactor to avoid `eval`; use safe parsing or whitelisted logic. |
| **4** | DOM-based XSS vulnerability | `/src/routes/videoHandler.ts` | Unsanitized `subs` variable injected into `<script>` context. | Sanitize or encode dynamic input before rendering in HTML. |
| **5** | Directory listing enabled | `/src/server.ts` | Static file server configuration may expose sensitive files (e.g., `.env`, backups). | Disable directory listing or restrict access to specific paths. |

---

### 🧠 Summary

- **Semgrep** successfully identified multiple **OWASP Top 10** categories (Injection, XSS, Insecure Configuration, Unsafe Code Execution).  
- While **fast and lightweight**, results must be **manually verified** to eliminate false positives.  
- Detected vulnerabilities highlight typical risks in Node.js apps — insecure database queries, unsafe code evaluation, and improper input handling.  

# TASK 2 — Dynamic Application Security Testing (DAST) with Multiple Tools

---

## ⚙️ Tool Comparison Overview

| Tool | Effectiveness Summary |
|------|------------------------|
| **OWASP ZAP** | Provided extensive application coverage; detected backup files, misconfigurations, missing security headers, and XSS risks. |
| **Nuclei** | Template-based scanner; accuracy depends on template quality and scope. No findings in this scan. |
| **Nikto** | Identified server and configuration issues, including header leaks and accessible directories (`/ftp/`, `robots.txt`). |
| **SQLmap** | Detected confirmed SQL Injection in parameter `q` of `/rest/products/search`. |

---

## Tool Strengths

- **ZAP:** Performs recursive crawling, discovers client- and server-side issues such as XSS, missing headers, and exposed backups.  
- **Nuclei:** Fast and flexible; ideal for known CVE templates and quick automation within CI/CD.  
- **Nikto:** Good at detecting server misconfigurations, outdated headers, and publicly accessible directories.  
- **SQLmap:** Specialized in SQL Injection detection and validation through automated exploitation.

---

## DAST Findings Summary

| Tool | Key Findings | Risk Level |
|------|---------------|-------------|
| **ZAP** | Backup file disclosure at `/ftp/quarantine%20-%20Copy`; missing security headers (e.g., CSP, X-Frame-Options). | **High** |
| **Nuclei** | No vulnerabilities detected in current template set. | — |
| **Nikto** | `ETag` header leakage, accessible `/ftp/` directory, exposed `robots.txt` entries. | **Medium** |
| **SQLmap** | Confirmed SQL Injection on parameter `q` in `/rest/products/search`. | **Critical** |

---

## Observations

- The **ZAP** scan demonstrated broad web coverage, confirming its value as a general-purpose DAST tool.  
- **SQLmap** provided deep injection analysis — valuable for confirming true-positive SQLi vulnerabilities.  
- **Nikto**’s findings emphasize the importance of hardening web server configurations.  
- **Nuclei** returned no findings, likely due to limited or generic template coverage for this target.

---

## Recommendations

1. **Remediate the confirmed SQL injection** (`/rest/products/search?q=`) — sanitize or parameterize database queries.  
2. **Remove or restrict public access** to `/ftp/` and backup files.  
3. **Add missing HTTP headers** — `Content-Security-Policy`, `Strict-Transport-Security`, and `X-Frame-Options`.  
4. **Enhance Nuclei configuration** with updated or custom templates to expand coverage.  
5. Integrate **ZAP** and **SQLmap** into CI/CD pipelines for routine DAST validation.

---

> **Conclusion:**  
> The combined use of **ZAP**, **Nikto**, and **SQLmap** delivers comprehensive dynamic testing coverage — balancing surface-level exploration with in-depth injection verification.  
> **Nuclei** enhances automation potential but requires continuous template updates for maximum effectiveness.

---

# TASK 3 — SAST/DAST Correlation and Security Assessment

---

## Findings Overview

| Tool | Findings Summary |
|------|------------------|
| **Semgrep (SAST)** | 25 findings — insecure code patterns (SQLi, XSS, unsafe `eval`). |
| **OWASP ZAP** | 16 findings — backup file exposure, missing headers, XSS risks. |
| **Nuclei** | 1 template match — no exploitable vulnerabilities confirmed. |
| **Nikto** | 14 findings — directory exposure (`/ftp/`), header leaks, `robots.txt` entries. |
| **SQLmap** | Confirmed SQL injection at `/rest/products/search?q=` (`results-10032025_0910am.csv`). |

**Correlation summary:**  
According to `labs/lab5/analysis/correlation.txt`, multiple issues overlap across SAST and DAST — especially **SQL Injection**, **XSS**, and **information disclosure**.

---

## ⚖️ SAST vs DAST Correlation Analysis

| Category | SAST Findings (Semgrep) | DAST Confirmation | Notes |
|-----------|--------------------------|------------------|-------|
| **SQL Injection** | Sequelize queries with string concatenation (`dbSchemaChallenge_1.ts`, `_3.ts`) | ✅ Confirmed by SQLmap (`/rest/products/search`) | True positive — exploitable |
| **Unsafe Code Execution** | Use of `eval` on untrusted input (`dbSchemaChallenge_1.ts`) | ⚠️ Not directly exploitable in runtime, but high-risk pattern | Requires refactor |
| **XSS / Injection** | DOM-based XSS in `videoHandler.ts` | ⚠️ Related header/XSS issues in ZAP | Partial overlap |
| **Information Disclosure** | Hardcoded paths, debug exposure | ✅ Confirmed by Nikto/ZAP (`/ftp/`, backup files) | True positive |
| **Configuration Weaknesses** | Missing validation / CSP | ✅ Detected via ZAP/Nikto | Aligns with DAST reports |

**Summary:**  
The strongest correlation lies in **SQLi** and **disclosure risks**, validated by both code-level and runtime testing.  
Semgrep’s early detection aligns with ZAP/Nikto/SQLmap dynamic results, confirming that vulnerable code paths are reachable in production.

---

## Integrated Security Recommendations

### High Priority
- **Fix SQL Injection:** Parameterize all Sequelize queries; verify `/rest/products/search` endpoint.  
- **Remove/Restrict Sensitive Directories:** `/ftp/` and backup files should not be publicly accessible.  
- **Secret Management:** Rotate any exposed tokens or keys in source.

### Medium Priority
- **XSS Protection:** Sanitize dynamic inputs and enable `Content-Security-Policy`.  
- **Header Hardening:** Add `HSTS`, `X-Content-Type-Options`, and `X-Frame-Options` headers.  
- **Error Handling:** Disable detailed error responses in production.

### Process & Automation
- **Shift Left:** Run **Semgrep** in CI for pre-merge security checks.  
- **Runtime Testing:** Schedule **ZAP**, **Nikto**, and **Nuclei** scans in staging environments.  
- **Regression Validation:** Use **SQLmap** on known injection points post-patch.  
- **Integration:** Automate triage → issue tracker (e.g., GitHub Security tab or Jira) to ensure remediation tracking.

---

## Summary

- Clear overlap between **SAST** and **DAST** results confirms true positives (SQLi, XSS, disclosure).  
- Static and dynamic tools complement each other — **Semgrep** identifies vulnerable code, while **ZAP/Nikto/SQLmap** validate exploitation feasibility.  
- Implementing automated, correlated scanning within CI/CD strengthens overall DevSecOps posture.

> **Conclusion:**  
> Correlating SAST and DAST outputs enables prioritization of real exploitable vulnerabilities, reduces noise, and drives focused remediation workflows.

---
