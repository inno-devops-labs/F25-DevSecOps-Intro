# Lab 5 Submission — Security Analysis: SAST & DAST of OWASP Juice Shop

## Task 1 — Static Application Security Testing with Semgrep

### SAST Tool Evaluation

The Semgrep analysis identified **25 security vulnerabilities** utilizing a combination of *security-audit* and *OWASP Top Ten* rule configurations.
Key strengths encompass semantic pattern matching capabilities for identifying sophisticated injection vulnerabilities, accurate file/line-level issue reporting, and comprehensive fix recommendations.
Vulnerability types discovered span **SQL injection, cross-site scripting (XSS), path traversal attacks,** and **cryptographic implementation flaws**.

### Critical Vulnerability Highlights

1. **SQL Injection (Critical)** — `/src/routes/login.ts:34`: Direct string concatenation within Sequelize queries creates authentication bypass opportunities.
2. **Path Traversal (High)** — `/src/routes/fileServer.ts:33`: Insufficient input validation when supplying user data to `res.sendFile()` permits directory traversal attacks.
3. **Hardcoded JWT Secret (High)** — `/src/lib/insecurity.ts:56`: JWT token signing utilizes a static hardcoded key rather than implementing secure secret management practices.
4. **XSS in Templates (Medium)** — `/src/frontend/src/app/navbar/navbar.component.html:17`: Template variables lacking proper escaping create script injection attack vectors.
5. **Open Redirect (Medium)** — `/src/routes/redirect.ts:19`: Redirection functionality accepts unvalidated user input directly without proper sanitization.

---

## Task 2 — Dynamic Application Security Testing with Multiple Tools

### Tool Comparison

* **ZAP**: 16 detected alerts (including backup file disclosures and configuration exposures) — optimal for thorough and detailed web application analysis, albeit with longer scan durations.
* **Nuclei**: 23 identified issues (exposures and misconfigurations) — highest velocity template-driven scanning solution.
* **Nikto**: 14 discovered findings (server information leaks and header issues) — specialized in server-level misconfiguration detection.
* **SQLmap**: Successfully identified SQL injection vulnerabilities — most effective for database-centric security assessment.

### Tool Strengths

**ZAP:** Comprehensive vulnerability coverage, dual active/passive scanning modes, granular risk assessment reporting.
**Nuclei:** High-speed CVE identification, extensive community-maintained template library, seamlessly integrates with CI/CD pipelines.
**Nikto:** Identifies legacy software versions, configuration weaknesses, and inadvertent sensitive information disclosure.
**SQLmap:** Fully automated injection exploitation, sophisticated payload crafting, and database fingerprinting capabilities.

### DAST Findings

* **ZAP:** Discovered backup file exposure at `/ftp/quarantine - Copy`, potentially leaking confidential information.
* **Nuclei:** Absence of critical security headers (COOP, CSP) elevating susceptibility to XSS and clickjacking attacks.
* **Nikto:** ETag inode information leakage and exposed `robots.txt` facilitating attacker reconnaissance activities.
* **SQLmap:** Confirmed SQL injection vulnerability at `/rest/products/search?q=apple` through boolean-based and time-based blind injection techniques.

---

## Task 3 — Correlation Between SAST and DAST

### SAST vs DAST Insights

**SAST Unique:** Source code level vulnerabilities — injection flaws, embedded credentials, XSS within templates, file path traversal.
**DAST Unique:** Application runtime vulnerabilities — deployment misconfigurations, information disclosure, backup file leakage, real-world exploit confirmation.

**Key Difference:**
SAST uncovers **development-phase coding vulnerabilities proactively**, whereas DAST confirms **operational behavior and deployment environment security posture**.

---

## Integrated Security Recommendations

**DevSecOps Workflow:**

1. **Development:** Embed Semgrep scanning within pre-commit hooks and pull request validations to catch injection vulnerabilities and cryptographic weaknesses.
2. **Staging:** Execute ZAP and Nuclei comprehensive dynamic security assessments against web application instances.
3. **Deployment:** Deploy Nikto for server hardening validation and SQLmap for database interface security testing.
4. **Automation:** Enforce SAST-based quality gate policies, orchestrate scheduled DAST scanning cycles, and implement continuous security monitoring via Nuclei.

This multi-layered security strategy enables **defense-in-depth** and sustains ongoing security assurance throughout the complete software development lifecycle.
