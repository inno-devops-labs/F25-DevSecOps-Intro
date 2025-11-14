# Lab 5 — Security Analysis: SAST & DAST of OWASP Juice Shop

## Task 1 — Static Application Security Testing with Semgrep



### 1.1 SAST Tool Effectiveness

Semgrep quickly detects common vulnerabilities in OWASP Juice Shop such as SQL Injection, XSS, Hardcoded Secrets, Path Traversal, and Open Redirect. It uses pattern-based scanning matching OWASP Top 10 risks. Semgrep works well for code-level issues but may miss runtime flaws. It is fast, customizable, and suitable for CI/CD integration.

### 1.2 Critical Vulnerabilities - Top 5 Findings

| #  | File Location                                    | Vulnerability      | Severity |
|----|-------------------------------------------------|--------------------|----------|
| 1  | src/datastatic/codefixes/unionSqlInjectionChallenge3.ts:10 | SQL Injection      | High     |
| 2  | src/lib/insecurity.ts:56                         | Hardcoded JWT Secret | Medium   |
| 3  | src/routes/redirect.ts:19                        | Open Redirect      | Medium   |
| 4  | src/routes/fileServer.ts:33                      | Path Traversal     | Medium   |
| 5  | src/frontend/src/app/navbarnavbar.component.html:17 | Cross-Site Scripting | Low/Medium |


## Task 2 — Dynamic Application Security Testing with Multiple Tools

### 2.1 Tool Comparison - ZAP vs Nuclei vs Nikto vs SQLmap

- **ZAP**: Broad application scanner with automated full-site crawling and vulnerability detection. Excels at finding common web issues like XSS, broken auth, and missing security headers.
- **Nuclei**: Template-based fast scanner focusing on known CVEs, misconfigurations, and specific exposed services. Very effective at targeted, pattern-matching security checks.
- **Nikto**: Classic web server scanner specialized in identifying outdated server components, misconfigurations, and default files/folders.
- **SQLmap**: Focused SQL injection detection tool; automates testing of injection points and database fingerprinting.

### 2.2 Tool Strengths

- ZAP provides in-depth, interactive scans with detailed reports on OWASP Top 10 risks.
- Nuclei is very fast and easily extensible with new templates.
- Nikto identifies server-level issues that other tools may miss.
- SQLmap automates complex injection attacks with powerful payload options.

### 2.3 DAST Findings - Significant Issues Identified

- **ZAP**:  Detected Backup File Disclosure vulnerability where backup copies of files are publicly accessible on the web server. These backup files may expose sensitive data like source code or configuration details. This increases risk of unauthorized access and data leakage. Medium severity. URLs included variants of /ftp/quarantine - Copy.
- **Nuclei**: Detected the presence of a public Swagger API at /api-docs/swagger.json.
This indicates the application exposes API documentation publicly, which can aid attackers in understanding and exploring the API endpoints. The severity level is informational, meaning it is not an immediate risk but worth noting for potential exposure.
- **Nikto**: Found several interesting issues including inodes leakage via ETags, uncommon HTTP headers like x-frame-options, x-recruiting, and feature-policy. Also detected publicly accessible directories (/ftp/, /css/, /public/) listed in robots.txt and not forbidden by the server, which could expose sensitive files or information. HTTP methods like PUT and DELETE are enabled, increasing attack surface.
- **SQLmap**: Detected a boolean-based blind SQL injection and time-based blind SQL injection on parameter "q" in the GET request. The boolean-based injection uses logical conditions to infer database behavior, while the time-based injection uses server response delays to confirm the vulnerability. The back-end database is SQLite. This vulnerability allows an attacker to extract sensitive data without direct query output, making it a high-risk issue.

This analysis indicates that each DAST tool covers different security aspects; using them together provides holistic web app vulnerability assessment.


## Task 3 — SAST/DAST Correlation and Security Assessment

### 3.1 Findings Counts Summary

- Total **SAST** findings (Semgrep): 25  
- Total **ZAP** findings: 15  
- Total **Nuclei** findings: 21  
- Total **Nikto** findings: 14  
- **SQLmap** results: Confirmed blind SQL Injection on parameter q in endpoint /rest/products/search. Backend DBMS: SQLite. Total 169 requests made to verify injection. 

### 3.2 SAST vs DAST Findings

- **SAST (Semgrep)** revealed 25 code-level issues including SQL Injection risks, hardcoded secrets, and insecure coding patterns. These represent potential vulnerabilities in the application’s source code before deployment.
- **DAST (ZAP, Nuclei, Nikto, SQLmap)** uuncovered 15 to 21 runtime vulnerabilities and configuration issues, such as backup file disclosures (ZAP), public API exposure (Nuclei), server misconfigurations (Nikto), and confirmed blind SQL Injection on parameter q in endpoint /rest/products/search (SQLmap) via boolean-based and time-based blind techniques. Backend DBMS was identified as SQLite.
- The findings show that while some vulnerabilities overlap, many are unique to either static or dynamic analysis due to different detection focuses—SAST targets code flaws, DAST targets live environment exposures.


### 3.3 Integrated Security Recommendations

- Incorporate **SAST** tools early in the development pipeline to catch insecure coding and design flaws prior to deployment.
- Use **DAST** tools continuously on staging or production environments to detect exploitable runtime vulnerabilities and configuration issues.
- Automate the integration of both SAST and DAST into the DevSecOps CI/CD pipeline for real-time, comprehensive security feedback.
- Correlate and prioritize remediation of issues found by both testing methods to enhance the overall security posture of the application.