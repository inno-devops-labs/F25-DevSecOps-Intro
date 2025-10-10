# Lab 5 Submission — Security Analysis: SAST & DAST of OWASP Juice Shop

## Task 1

### SAST Tool Effectiveness

**Semgrep Detection Capabilities:**
- **Total Findings:** 25 security vulnerabilities detected across the codebase
- **Coverage:** Comprehensive analysis covering OWASP Top 10 and security audit patterns
- **Detection Types:** Successfully identified SQL injection, XSS, hardcoded credentials, path traversal, and configuration issues
- **False Positive Rate:** Low - most findings appear to be legitimate security concerns
- **Performance:** Efficient scanning with detailed location information (line and column numbers)

**Semgrep Strengths:**
- Pattern-based detection with high accuracy for common vulnerability patterns
- Almost full coverage of backend JavaScript/TypeScript security issues
- Detailed metadata including severity levels and remediation links
- Good integration potential for CI/CD pipelines
- Comprehensive rule sets (security-audit + OWASP Top 10)

**Semgrep Limitations Observed:**
- Some syntax parsing errors on specific files (21 errors reported)
- Limited analysis of frontend Angular components (only 3 frontend findings vs 22 backend)
- Template/configuration files showed parsing challenges

### Critical Vulnerability Analysis

#### 1. SQL Injection Vulnerabilities (ERROR Severity)
**Files Affected:** 
- `/src/routes/login.ts:34`
- `/src/routes/search.ts:23` 
- `/src/data/static/codefixes/dbSchemaChallenge_1.ts:5`
- `/src/data/static/codefixes/unionSqlInjectionChallenge_1.ts:6`

**Description:** Multiple instances of unsanitized user input directly concatenated into SQL queries
**Example:** `SELECT * FROM Users WHERE email = '${req.body.email || ''}' AND password = '${security.hash(req.body.password || '')}' AND deletedAt IS NULL`
**Risk:** High - Allows SQL injection attacks leading to data breach, authentication bypass
**Recommendation:** Use parameterized queries with bind parameters

#### 2. Code Injection via eval() (ERROR Severity)
**File:** `/src/routes/userProfile.ts:62`
**Description:** User-controllable data flows directly to `eval()` function
**Code:** `username = eval(code) // eslint-disable-line no-eval`
**Risk:** Critical - Remote code execution vulnerability
**Recommendation:** Remove eval() usage, implement safe parsing alternatives

#### 3. Hardcoded JWT Secret (WARNING Severity)
**File:** `/src/lib/insecurity.ts:56`
**Description:** JWT signing key appears to be hardcoded in source code
**Risk:** Medium - Compromises JWT token security if source code is exposed
**Recommendation:** Move JWT secrets to environment variables or secure vault

#### 4. Path Traversal Vulnerabilities (WARNING Severity)
**Files Affected:**
- `/src/routes/fileServer.ts:33`
- `/src/routes/keyServer.ts:14`
- `/src/routes/logfileServer.ts:14`
- `/src/routes/quarantineServer.ts:14`

**Description:** User input passed directly to `res.sendFile()` without path validation
**Example:** `res.sendFile(path.resolve('ftp/', file))`
**Risk:** High - Arbitrary file read access through directory traversal
**Recommendation:** Implement path validation and sanitization, use allowlists

#### 5. Cross-Site Scripting (XSS) Vulnerabilities (WARNING Severity)
**Files Affected:**
- `/src/routes/chatbot.ts:197` (Raw HTML construction)
- `/src/routes/videoHandler.ts:58,71` (Script tag injection)
- Multiple frontend templates with unquoted attributes

**Description:** User data flows into HTML/script contexts without proper sanitization
**Risk:** Medium-High - Client-side code execution, session hijacking
**Recommendation:** Use proper HTML encoding, Content Security Policy, sanitization libraries

## Task 2 — Dynamic Application Security Testing with Multiple Tools (5 pts)

### Tool Comparison

**DAST Tool Effectiveness Analysis:**
- **ZAP:** 15 unique vulnerability types detected with comprehensive web application analysis
- **Nuclei:** 1 DNS rebinding detection (focused template-based approach)
- **Nikto:** 28 findings focused on server configuration and information disclosure
- **SQLmap:** Successfully identified SQL injection vulnerability with detailed payload analysis

**Coverage Comparison:**
- **ZAP** provided the most comprehensive web application security analysis
- **Nuclei** had limited findings but detected specific DNS-related issues
- **Nikto** excelled at server-level configuration analysis
- **SQLmap** provided deep SQL injection testing with exploitation proof

### Tool Strengths

#### OWASP ZAP Strengths
- **Comprehensive Web App Testing:** Covers OWASP Top 10 vulnerabilities systematically
- **CORS Analysis:** Detailed detection of cross-origin resource sharing misconfigurations
- **Backup File Discovery:** Extensive detection of backup files and directories
- **HTTP Security Headers:** Analysis of missing security headers (CSP, COEP, etc.)
- **Authentication Bypass:** Detection of 403 bypass techniques

#### Nuclei Strengths
- **Template-Based Detection:** Fast execution using community-driven vulnerability templates
- **DNS Security Testing:** Specific focus on DNS rebinding and network-level attacks
- **CVE Detection:** Excellent for known vulnerability patterns
- **Lightweight Scanning:** Minimal resource consumption
- **Automation-Friendly:** Easy integration into CI/CD pipelines

#### Nikto Strengths
- **Server Configuration Analysis:** Deep inspection of web server misconfigurations
- **Information Disclosure:** Detection of sensitive files and directories
- **HTTP Header Analysis:** Comprehensive header security assessment
- **Robots.txt Analysis:** Thorough examination of exposed paths
- **ETag Information Leakage:** Detection of server information disclosure

#### SQLmap Strengths
- **SQL Injection Specialization:** Deep analysis of SQL injection vulnerabilities
- **Database Fingerprinting:** Accurate identification of backend database (SQLite detected)
- **Payload Generation:** Advanced injection technique testing (boolean-based, time-based blind)
- **Exploitation Capability:** Actual proof of SQL injection with working payloads
- **Database-Specific Testing:** Tailored attacks for different DBMS types

### DAST Findings

#### 1. ZAP Finding: CORS Misconfiguration (Medium Risk)
**Vulnerability:** Cross-Origin Resource Sharing allows arbitrary domain access
**Details:** 
- **Location:** Multiple endpoints including `/`, `/ftp/`, `/assets/`
- **Evidence:** `Access-Control-Allow-Origin: *` header present
- **Attack Vector:** `origin: http://0BgxNQLH.com` successfully accepted
- **Impact:** Allows malicious websites to perform cross-origin requests
- **Risk:** Medium - Enables data theft from unauthenticated endpoints

**Remediation:** Configure specific allowed origins instead of wildcard (`*`)

#### 2. Nuclei Finding: DNS Rebinding Attack Detection
**Vulnerability:** DNS rebinding attack vector identified
**Details:**
- **Template:** `dns-rebinding.yaml`
- **Evidence:** localhost resolves to `127.0.0.1` (private IP)
- **Attack Vector:** DNS queries returning private IP addresses
- **Impact:** Potential bypass of same-origin policy through DNS manipulation
- **Risk:** Unknown severity but indicates network-level attack surface

**Remediation:** Implement DNS rebinding protection in application firewall

#### 3. Nikto Finding: Information Disclosure through Server Headers
**Vulnerability:** Server information leakage and exposed directories
**Details:**
- **ETag Leakage:** Server leaks inodes via ETags (`0xW/124fa 0x199cf49c8b7`)
- **Exposed Directories:** `/ftp/`, `/css/`, `/public/` accessible
- **Custom Headers:** `x-recruiting: /#/jobs` reveals application structure
- **Robots.txt Exposure:** Contains accessible paths that should be restricted
- **Impact:** Information gathering for targeted attacks

**Remediation:** Configure server to suppress information disclosure headers

#### 4. SQLmap Finding: SQL Injection Vulnerability (Critical)
**Vulnerability:** SQL injection in product search functionality
**Details:**
- **Location:** `http://localhost:3000/rest/products/search?q=apple`
- **Parameter:** `q` (GET parameter)
- **Injection Types Detected:**
  - Boolean-based blind: `q=apple%' AND 7004=7004 AND 'sgGK%'='sgGK`
  - Time-based blind: SQLite-specific heavy query injection
- **Database:** SQLite backend confirmed
- **Impact:** Critical - Full database access, data extraction possible

**Remediation:** Implement parameterized queries and input validation

### Tool Selection Recommendations

**For DevSecOps Integration:**
- **ZAP:** Comprehensive security testing in staging/QA environments
- **Nuclei:** Fast vulnerability scanning in CI/CD pipelines for known CVEs
- **Nikto:** Server configuration assessment during deployment validation
- **SQLmap:** Targeted SQL injection testing when database interactions are present

**Optimal Usage Strategy:**
1. **Continuous Integration:** Nuclei for fast template-based scanning
2. **Pre-Production:** ZAP for comprehensive web application testing
3. **Infrastructure Assessment:** Nikto for server configuration validation
4. **Penetration Testing:** SQLmap for deep database security assessment
