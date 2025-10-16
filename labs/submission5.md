# Lab 5 — Security Analysis: SAST & DAST of OWASP Juice Shop

## Task 1 — Static Application Security Testing with Semgrep

### SAST Tool Effectiveness

- **Findings**: 25 security issues (all blocking)
- **Coverage**: 1,014 files across TypeScript, JSON, YAML, HTML
- **Rules**: 140 security rules executed successfully
- **Performance**: Good multi-language support, 3 timeouts in complex files

### Critical Vulnerability Analysis

1. **SQL Injection** - HIGH
    - `routes/products.ts:156`
    - Unsanitized user input in SQL queries

2. **XSS Vulnerability** - HIGH
    - `frontend/src/app/product-review.component.ts:89`
    - User input without output encoding

3. **Insecure Direct Object Reference** - MEDIUM
    - `routes/userProfile.ts:203`
    - Missing authorization checks

4. **Hardcoded Credentials** - MEDIUM
    - `config/database.ts:45`
    - Database credentials in source code

5. **Path Traversal** - HIGH
    - `routes/fileUpload.ts:112`
    - Unsanitized file path operations

## Task 2 — Dynamic Application Security Testing with Multiple Tools

### Tool Comparison

|Tool|Findings|Effectiveness|
|---|---|---|
|**OWASP ZAP**|16|Most comprehensive - found diverse vulnerability types|
|**Nuclei**|3|Targeted detection - focused on specific known issues|
|**Nikto**|14|Server-focused - identified configuration problems|
|**SQLmap**|**CRITICAL**|Specialized - deep SQL injection analysis

### Tool Strengths

**ZAP**: Comprehensive web app scanning - authentication, session management, business logic  

**Nuclei**: Fast template-based scanning for known CVEs and misconfigurations  

**Nikto**: Server security headers, outdated software, web server misconfigurations 

**SQLmap**: Deep SQL injection testing with advanced exploitation techniques

### DAST Findings

**ZAP - XSS Vulnerability**

- Reflected XSS in search functionality
- User input not sanitized before rendering
- Risk: Attackers can execute scripts in user browsers

**Nuclei - Security Misconfiguration**

- Missing security headers (CSP, X-Frame-Options)
- Increases risk of clickjacking and XSS attacks
- Easy to fix with proper header configuration

**Nikto - Server Information Disclosure**

- Server version and technology stack exposed
- Potential attackers can target known vulnerabilities
- Recommends obscuring server information

**SQLmap - CRITICAL SQL Injection**

- **Boolean-based blind SQL injection** in `/rest/products/search?q=`
- **Time-based blind SQL injection** confirmed
- **Backend DBMS**: SQLite
- **Impact**: Full database access, data theft, and potential server compromise

## Task 3 — SAST/DAST Correlation and Security Assessment

### SAST vs DAST Findings

**SAST Unique Discoveries (25 findings):**

- **Code-level issues**: Hardcoded credentials, insecure coding patterns
- **Potential vulnerabilities**: Code that could be exploited under certain conditions
- **Configuration problems**: Security misconfigurations in source files
- **Maintenance issues**: Code quality and anti-patterns

**DAST Unique Discoveries (16 ZAP + 3 Nuclei + 14 Nikto + SQL Injection):**

- **Runtime vulnerabilities**: Actual exploitable SQL injection confirmed
- **Server misconfigurations**: Missing security headers, exposed server info
- **Business logic flaws**: Authentication and session management issues
- **Real-world exploitation**: Verified SQL injection with working payloads

**Key Differences:**

- **SAST** found more potential issues (25 vs 16) but couldn't verify exploitability
- **DAST** found fewer but confirmed critical vulnerabilities (SQL injection)
- **SQL Injection**: SAST warned about potential, DAST proved it's exploitable

### Integrated Security Recommendations

1. **SAST in Development Phase**

	**Every commit**
	
    - semgrep scan on PR
    - Block merge if critical findings

2. **DAST in Staging Phase**
    
    **After deployment to staging**:
    
    - ZAP automated scan
    - SQLmap on high-risk endpoints
    - Nuclei for known vulnerabilities

3. **Correlation & Triage**
    
    - Prioritize vulnerabilities found by both tools
    - Use SAST to guide DAST testing focus
    - Validate SAST findings with DAST results

**Immediate Actions:**

1. **CRITICAL**: Fix SQL injection in search endpoint
2. **HIGH**: Implement input validation and parameterized queries
3. **MEDIUM**: Add security headers and obscure server information
4. **LOW**: Address code quality issues from SAST
