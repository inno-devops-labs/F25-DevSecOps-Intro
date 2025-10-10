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

## Task 2

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
4. **Penetration Testing:** SQLmap for database security assessment

## Task 3

### SAST vs DAST Findings

**Quantitative Analysis:**
- **SAST (Semgrep):** 25 vulnerabilities detected in source code
- **DAST Tools Combined:** 86 findings across runtime testing
  - ZAP: 15 web application vulnerabilities
  - Nuclei: 28 template-based detections
  - Nikto: 28 server configuration issues
  - SQLmap: 1 confirmed SQL injection with exploitation proof

**Unique SAST Discoveries:**
1. **Code-Level Vulnerabilities:** Semgrep identified hardcoded JWT secrets, eval() usage, and unsafe string concatenation that DAST tools cannot detect from external testing
2. **Development Anti-Patterns:** Found insecure coding patterns in challenge files and static codefixes that represent intentional vulnerabilities
3. **Template Security Issues:** Detected unquoted HTML attributes in Angular templates that could lead to XSS
4. **Backend Logic Flaws:** Identified multiple Sequelize ORM injection points that require source code analysis

**Unique DAST Discoveries:**
1. **Runtime Configuration Issues:** DAST tools found CORS misconfigurations, missing security headers, and server information disclosure that don't exist in source code
2. **Backup File Exposure:** ZAP discovered accessible backup files (`quarantine - Copy`) that represent deployment security issues
3. **HTTP-Level Vulnerabilities:** Nikto found ETag information leakage and exposed directory listings not visible in static analysis
4. **Exploitation Validation:** SQLmap provided actual exploitation proof of SQL injection vulnerabilities with working payloads

**Complementary Coverage Analysis:**
- **SAST Strength:** Deep source code analysis revealing logic flaws and coding vulnerabilities
- **DAST Strength:** Runtime behavior analysis revealing configuration and deployment issues
- **Overlap Area:** SQL injection detected by both approaches with different detail levels
  - SAST: Identified vulnerable code patterns and locations
  - DAST: Confirmed exploitability with actual attack payloads

**Coverage Gaps Identified:**
- **SAST Limitations:** Cannot detect runtime configuration issues, deployment-specific vulnerabilities, or business logic flaws requiring user interaction
- **DAST Limitations:** Cannot analyze internal code logic, detect unused vulnerable code paths, or identify issues in unlinked functionality

### Integrated Security Recommendations

#### DevSecOps Pipeline Integration Strategy

**Phase 1: Development (SAST-First Approach)**
```yaml
Pre-Commit Stage:
- Tool: Semgrep with security-audit ruleset
- Trigger: Every code commit
- Action: Block commits with ERROR-level findings
- Focus: Prevent vulnerable code from entering repository

Pull Request Stage:
- Tool: Semgrep with comprehensive rule sets
- Trigger: PR creation/updates
- Action: Automated security review comments
- Focus: Educational feedback for developers
```

**Phase 2: Continuous Integration (Fast DAST)**
```yaml
CI Pipeline Stage:
- Tool: Nuclei with community templates
- Trigger: Branch builds and merges
- Action: Fail build on HIGH severity findings
- Focus: Known CVE detection and quick security validation

Infrastructure Validation:
- Tool: Nikto for server configuration
- Trigger: Infrastructure changes
- Action: Report configuration security issues
- Focus: Server hardening and information disclosure prevention
```

**Phase 3: Pre-Production (Comprehensive DAST)**
```yaml
Staging Environment:
- Tool: OWASP ZAP full scan
- Trigger: Release candidate deployment
- Action: Comprehensive security assessment
- Focus: OWASP Top 10 validation and business logic testing

Specialized Testing:
- Tool: SQLmap for database interactions
- Trigger: Database schema changes or new endpoints
- Action: Deep SQL injection testing
- Focus: Database security validation
```

#### Tool Orchestration Workflow

**Recommended Integration Sequence:**
1. **Developer Workstation:** Semgrep IDE plugins for real-time feedback
2. **Git Hooks:** Pre-commit Semgrep scan with fail-fast on critical issues
3. **CI/CD Pipeline:** 
   - Fast Nuclei scan (< 5 minutes)
   - Parallel Nikto configuration check
   - Conditional SQLmap testing for database endpoints
4. **Staging Deployment:** Comprehensive ZAP scan with full crawling
5. **Production Monitoring:** Continuous security monitoring integration

#### Risk-Based Tool Selection Matrix

| Vulnerability Type | Primary Tool | Secondary Tool | Pipeline Stage |
|-------------------|--------------|----------------|----------------|
| SQL Injection | Semgrep | SQLmap | Development → Staging |
| XSS/Code Injection | Semgrep | ZAP | Development → Pre-prod |
| Authentication/Authorization | ZAP | Manual Testing | Staging |
| Configuration Issues | Nikto | ZAP | Infrastructure |
| Known CVEs | Nuclei | Manual Research | CI/CD |
| Business Logic | Manual Testing | ZAP | Pre-production |

#### Security Metrics and KPIs

**SAST Metrics:**
- Vulnerability detection rate in development
- Time to fix critical issues (< 24h target)
- False positive rate monitoring
- Developer security training effectiveness

**DAST Metrics:**
- Runtime vulnerability discovery rate
- Configuration drift detection
- Penetration testing validation rate
- Production security incident correlation

#### Continuous Improvement Process

**Feedback Loop Implementation:**
1. **Production Incidents → SAST Rules:** Update Semgrep rules based on production vulnerabilities
2. **DAST Findings → Development Training:** Use runtime discoveries for developer education
3. **Tool Correlation Analysis:** Monthly review of SAST/DAST overlap and gaps
4. **Rule Tuning:** Continuous refinement based on false positive rates

**Security Culture Integration:**
- Weekly security meetings reviewing tool findings
- Integration of security findings into sprint planning


