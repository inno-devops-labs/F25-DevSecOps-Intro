# Lab 5 Submission — Security Analysis: SAST & DAST of OWASP Juice Shop

## Task 1 — Static Application Security Testing with Semgrep

### SAST Tool Effectiveness

Semgrep identified 25 security vulnerabilities using combined security-audit and OWASP Top Ten rulesets. Key strengths include semantic pattern recognition for complex injection flaws, detailed file/line location reporting, and actionable remediation guidance. Coverage included SQL injection, XSS, path traversal, and cryptographic weaknesses.

### Critical Vulnerability Analysis

1. **SQL Injection (Critical)** - `/src/routes/login.ts:34`: String concatenation in Sequelize query enables SQL injection for authentication bypass.

2. **Path Traversal (High)** - `/src/routes/fileServer.ts:33`: User input passed to `res.sendFile()` without validation allows directory traversal.

3. **Hardcoded JWT Secret (High)** - `/src/lib/insecurity.ts:56`: JWT signing uses hardcoded private key instead of secure key management.

4. **XSS in Templates (Medium)** - `/src/frontend/src/app/navbar/navbar.component.html:17`: Unquoted template variables enable JavaScript injection.

5. **Open Redirect (Medium)** - `/src/routes/redirect.ts:19`: User input used directly in redirect without validation.

## Task 2 — Dynamic Application Security Testing with Multiple Tools

### Tool Comparison

- **ZAP**: 16 alerts (backup disclosures, configs) - Best for comprehensive web app scanning, but so long
- **Nuclei**: 23 findings (exposures, misconfigs) - Fastest template-based scanning
- **Nikto**: 14 issues (server leaks, headers) - Specialized web server scanner
- **SQLmap**: SQL injection exploits - Superior database vulnerability detection

### Tool Strengths

**ZAP**: Comprehensive scanning, passive/active modes, detailed risk assessment.  
**Nuclei**: Fast CVE detection, community templates, CI/CD integration.  
**Nikto**: Server misconfigurations, information disclosure, infrastructure focus.  
**SQLmap**: Detailed injection payloads, multiple techniques, database fingerprinting.

### DAST Findings

**ZAP**: Backup file disclosure at `/ftp/quarantine - Copy` - exposes sensitive backup data.  
**Nuclei**: Missing security headers (COOP, CSP) - increases XSS/clickjacking risk.  
**Nikto**: Server inode leaks via ETags, robots.txt exposures - aids reconnaissance.  
**SQLmap**: SQL injection at `/rest/products/search?q=apple` with boolean/time-based techniques.

## Task 3 — SAST/DAST Correlation and Security Assessment

### SAST vs DAST Findings

**SAST Unique**: Code injection patterns, hardcoded secrets, template XSS, path traversal logic.  
**DAST Unique**: Runtime config issues, backup file exposure, server misconfigurations, active exploitation validation.

**Key Differences**: SAST finds implementation flaws early; DAST validates runtime behavior and environment configs.

### Integrated Security Recommendations

**DevSecOps Integration:**
1. **Development**: Semgrep in pre-commit/PR checks for injection/cryptographic flaws
2. **Staging**: ZAP + Nuclei for comprehensive web app testing
3. **Deployment**: Nikto for server validation, SQLmap for database endpoints
4. **Automation**: SAST quality gates, scheduled DAST scans, Nuclei monitoring

This approach provides defense-in-depth coverage across the development lifecycle.
