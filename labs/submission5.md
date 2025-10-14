
## Task 1 — Static Application Security Testing with Semgrep

### SAST Tool Evaluation

Semgrep is a powerful SAST tool that can identify vulnerabilities based on semantic code analysis. It effectively detects critical security issues, including SQL injections, XSS, and path traversal. With precise file and line-level vulnerability localization, Semgrep makes it easier to fix vulnerabilities. The tool supports flexible rules, including OWASP Top Ten and security-audit. Its high speed and transparency make it suitable for CI/CD integration.

### Critical Vulnerability Highlights

1. XSS via <script> tag  
   File: /src/routes/videoHandler.ts, line 71: An unverified value of subs is inserted inside the <script> tag, which can lead to the execution of malicious JavaScript.

2. Directory Listing  
   File: /src/server.ts, line 269: Directory indexing is enabled through serveIndex, which can expose sensitive files.

3. Directory Listing — sensitive paths  
   File: /src/server.ts, lines 277–281: Access to directories like /encryptionkeys and /support/logs may result in sensitive data leakage.

4. Unquoted Template Variable  
   File: /src/views/dataErasureForm.hbs, line 21: The variable {{userEmail}} is used without quotes in an HTML attribute, which may allow the injection of JavaScript handlers.

5. XSS through string comparison  
   File: /src/routes/videoHandler.ts, line 58: Checking for the presence of a malicious script in subs without prior sanitization may not be sufficient to prevent XSS.
---


## Task 2 — Dynamic Application Security Testing with Multiple Tools

### Tool Comparison

- **ZAP** - 16 vulnerabilities: backups, configuration errors. In-depth analysis of web applications.
- **Nuclei** - 23 findings: leaks, configuration errors. Fast template scanner.
- **Nikto** - 14 findings: server leaks, headers. Focused on server security.
- **SQLmap** - confirmed SQL injections. Best for database testing.

### Strengths

- **ZAP**: active/passive analysis, detailed reports.
- **Nuclei**: quick CVE check, templates, CI/CD.
- **Nikto**: detection of outdated software and configurations.
- **SQLmap**: automation of injections and DBMS analysis.

### DAST results

- **ZAP**: leakage of backup files under the path `/ftp/quarantine`.
- **Nuclei**: missing COOP and CSP headers.
- **Nikto**: inode leak via ETag and access to `robots.txt`.
- **SQLmap**: SQL injection on `/rest/products/search?q=apple`.


## Task 3 — Correlation Between SAST and DAST

### SAST vs DAST Insights

**SAST** identifies vulnerabilities at the source code level - injections, hard-coded secrets, XSS in templates, and workarounds.  
**DAST** detects issues during runtime - configuration errors, data leaks, backups, and confirmed exploits.

**Key difference:**  
SAST helps to find implementation errors at an early stage, while DAST checks the application behavior and the security of the environment in real time.

---

## Integrated Security Recommendations

**DevSecOps approach:**

1\. **Development:** Use Semgrep in pre-commit and pull request to search for injections and cryptographic errors.
2\. **Staging:** Apply ZAP and Nuclei for dynamic analysis of a web application.
3\. **Production:** Check servers with Nikto and test databases through SQLmap.
4\. **Automation:** Set up SAST quality gates, run regular DAST scans, and use Nuclei for continuous monitoring.

 This multi-level approach ensures reliable protection at all stages of the development lifecycle.