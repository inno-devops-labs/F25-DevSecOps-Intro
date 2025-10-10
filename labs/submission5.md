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
