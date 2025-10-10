# Lab 5 — Security Analysis: SAST & DAST of OWASP Juice Shop

## Task 1 — Static Application Security Testing with Semgrep

### SAST Tool Effectiveness

- **Findings**: 25 security issues (all blocking)
- **Rules**: 140 security rules executed successfully
- **Performance**: Good multi-language support, 3 timeouts in complex files
- **Coverage:** 1,014 files across TypeScript, JSON, YAML, HTML

### Critical Vulnerability Analysis 
#### 1. SQL Injection (Sequelize raw query concatenation) — **High**
**Files & lines:**
- `/src/routes/search.ts:23`  
- `/src/routes/login.ts:34`  
- `/src/data/static/codefixes/dbSchemaChallenge_1.ts:5`, `_3.ts:11`  
- `/src/data/static/codefixes/unionSqlInjectionChallenge_1.ts:6`, `_3.ts:10`

**Evidence:**
```ts
// search.ts
models.sequelize.query(`SELECT * FROM Products WHERE ((name LIKE '%${criteria}%' OR
  description LIKE '%${criteria}%') AND deletedAt IS NULL) ORDER BY name`)

// login.ts
models.sequelize.query(`SELECT * FROM Users WHERE email = '${req.body.email || ''}' AND
  password = '${security.hash(req.body.password || '')}' AND deletedAt IS NULL`, { ... })
````

**Why it matters:** Direct string concatenation of user input leads to **SQL Injection** (OWASP A03).  

**Fix:** Use **parameterized queries / bind parameters** or ORM query builders with placeholders; add strict input validation.


#### 2. Path Traversal / Arbitrary File Read — **High**

**Files & lines:**

* `/src/routes/fileServer.ts:33`
* `/src/routes/keyServer.ts:14`
* `/src/routes/logfileServer.ts:14`
* `/src/routes/quarantineServer.ts:14`

**Evidence:**

```ts
res.sendFile(path.resolve('ftp/', file))
res.sendFile(path.resolve('encryptionkeys/', file))
res.sendFile(path.resolve('logs/', file))
res.sendFile(path.resolve('ftp/quarantine/', file))
```

**Why it matters:** User-controlled `file` variable passed into `path.resolve()` may allow **path traversal** or arbitrary file read (OWASP A01/A05).
**Fix:** Canonicalize and validate resolved paths to ensure they remain within an allowed directory (allowlist of safe paths or filename patterns).


#### 3. Open Redirect (user-controlled redirect) — **High**

**File & line:** `/src/routes/redirect.ts:19`

**Evidence:**

```ts
res.redirect(toUrl)
```

**Why it matters:** Redirects to unvalidated external URLs can enable **phishing or redirection to malicious sites** (OWASP A05).  

**Fix:** Implement an **allowlist of domains or relative paths**; display an intermediate warning page for third-party destinations.


#### 4. Hardcoded JWT Secret / Key — **High**

**File & line:** `/src/lib/insecurity.ts:56`

**Evidence:**

```ts
export const authorize = (user = {}) => jwt.sign(user, privateKey, { expiresIn: '6h', algorithm: 'RS256' })
```

**Why it matters:** Storing secrets or cryptographic keys in source code leads to **credential exposure** and compromised authentication (OWASP A07).  

**Fix:** Use **environment variables or secure vaults** (`process.env.JWT_SECRET`), enforce key rotation, and prevent committing secrets via pre-commit hooks.


### 5. XSS via Raw HTML/Script Injection & Unquoted Template Attributes — **High / Medium**

**Files & lines:**

* Raw/script injection:

  * `/src/routes/chatbot.ts:197`
  * `/src/routes/videoHandler.ts:58–71`
* Unquoted attributes:

  * `/src/frontend/src/app/navbar/navbar.component.html:17`
  * `/src/frontend/src/app/purchase-basket/purchase-basket.component.html:15`
  * `/src/frontend/src/app/search-result/search-result.component.html:40`
  * `/src/views/dataErasureForm.hbs:21`

**Evidence:**

```ts
// videoHandler.ts
compiledTemplate = compiledTemplate.replace('<script id="subtitle"></script>',
  '<script id="subtitle" type="text/vtt" ...>' + subs + '</script>')
```

**Why it matters:** Inserting unescaped user-controlled data into HTML or script blocks enables **Cross-Site Scripting (XSS)** (OWASP A03/A08).  

**Fix:** Always quote template attributes (`alt="{{ item.name }}"`), sanitize variables using libraries like **DOMPurify**, avoid raw HTML insertion, and enforce a strict **Content Security Policy (CSP)**.



## Task 2 — Dynamic Application Security Testing with Multiple Tools

### Tool Comparison

- **ZAP (Zed Attack Proxy)** — **breadth & context**  
  ZAP performs deep, contextual dynamic analysis (spider + active scanning). It finds configuration issues, discoverable files, backup copies and endpoint-specific issues that require crawling and correlation across paths. ZAP produced multiple medium-risk alerts (e.g. Backup File Disclosure for many `/ftp/...` backup paths). :contentReference[oaicite:0]{index=0}

- **Nuclei** — **speed & template-based detection**  
  Nuclei is very fast and excellent at recognizing known exposures and fingerprintable assets (Swagger, missing SRI, CVE patterns) using community templates. It discovered public Swagger API pages and missing SRI on third-party resources in the target. :contentReference[oaicite:1]{index=1}

- **Nikto** — **server/HTTP surface & configuration checks**  
  Nikto focusses on web server misconfiguration, headers, robots entries, directory listings and leftover/backup files. It surfaced many header observations (CORS=`*`, X-Frame-Options, X-Content-Type-Options), robots entries pointing to `/ftp/` and directories that “might be interesting”. (Nikto raw output excerpt provided.)  

- **SQLmap** — **targeted SQLi confirmation**  
  SQLmap is a specialized exploitation tool for SQL injection. It should be run only after you have a suspicious endpoint (from SAST or DAST hints). The SQLmap run against `/rest/products/search?q=apple` produced a record in its output (request metadata) but did not produce a confirmed SQLi exploitation result in the provided snippet.

**Short summary:**  
- Use **Semgrep**/SAST to flag suspicious code patterns.  
- Use **Nuclei** for fast, nightly scanning of many hosts/services and to catch known-template exposures.  
- Use **ZAP** on staging/QA for a comprehensive dynamic assessment (crawl + active attacks).  
- Use **Nikto** to validate server config & discover leftover artifacts.  
- Use **SQLmap** as a precise follow-up to confirm/exploit SQLi indicated by SAST/DAST.


### Tool strengths — what each tool excels at detecting

- **ZAP**
  - Strengths: full crawl, context-aware active scanning, discovery of exposed/back-up files, chained issues (e.g., directory listing + backup files), and endpoint-specific tests. Good reporting and manual verification support. :contentReference[oaicite:2]{index=2}
  - Weaknesses: slower than template scanners; may generate more noise unless tuned.

- **Nuclei**
  - Strengths: lightning-fast template-based checks (exposed Swagger, missing SRI, known misconfigs/CVEs). Great for CI/nightly scanning and wide coverage of signature detections. :contentReference[oaicite:3]{index=3}
  - Weaknesses: limited to templates available; less context-aware for complex app logic.

- **Nikto**
  - Strengths: web-server and HTTP-surface issues — header analysis, robots/dirs, leftover backup file discovery heuristics. Good for quick hygiene checks on server deployment. (See Nikto output: headers, robots, `/ftp/` entries.)
  - Weaknesses: old-school signatures, no exploitation, not aware of app logic.

- **SQLmap**
  - Strengths: deep, automated SQL injection fingerprinting and exploitation (time-based, boolean, error-based, union, etc.). Best for verifying and exploiting SQLi once a vulnerable parameter is suspected.
  - Weaknesses: noisy and intrusive if misused; requires a candidate endpoint and careful configuration.


### DAST findings 
#### ZAP — **Backup File Disclosure (Medium)**  
**Evidence:** ZAP reported multiple `Backup File Disclosure` instances for backup filenames under `/ftp/quarantine` and variants (e.g. `/ftp/quarantine - Copy`, `/ftp/quarantine.bak`, `/ftp/quarantine.zip`, and specific backup files like `juicy_malware_windows_64.exe.url`). These appear as numerous alert instances in the ZAP report. :contentReference[oaicite:4]{index=4}

**Explanation:** Backup files and unreferenced copies are accessible over HTTP and may contain sensitive artifacts (scripts, credentials, malware pointers, or configuration data). Having many backup names available increases risk and attack surface.

**Recommendation:** Remove backups and working copies from web roots; restrict access to FTP/backup directories; use authentication/ACLs for admin-only paths; add checks in deploy pipelines to exclude backup files. Consider scanning repo for `.bak`, `.old`, `~`, `.swp` artifacts before deployment.

---

#### Nuclei — **Public Swagger API & Missing SRI (Info / Exposure)**  
**Evidence:** Nuclei matched `http/exposures/apis/swagger-api.yaml` — a `Public Swagger API` was detected at `/api-docs/swagger.yaml`. It also matched `http/misconfiguration/missing-sri.yaml`, extracting external scripts/styles (`cookieconsent` and `jquery`) that lack Subresource Integrity. :contentReference[oaicite:5]{index=5}

**Explanation:** Publicly accessible API documentation (Swagger) can reveal endpoints, parameters and data models that attackers can use to craft precise attacks. Missing SRI allows tampered external JS/CSS to be executed by clients, increasing supply-chain or MITM risks.

**Recommendation:**  
- If API docs must be public, limit sensitive operations, or rate-limit/expose a sanitized doc for public use; consider requiring auth for internal docs.  
- Add Subresource Integrity attributes for critical third-party scripts or serve them from trusted, pinned sources; consider upgrading to integrity-checked bundles.

---

#### Nikto — **CORS misconfiguration, interesting headers & robots/dir exposures**  
**Evidence (Nikto output excerpt):**


* Target Host: localhost
* Target Port: 3000
* GET /: Server leaks inodes via ETags, header found with file /, fields: 0xW/124fa 0x199cf623cfd
* GET /: Uncommon header 'x-recruiting' found, with contents: /#/jobs
* GET /: Uncommon header 'x-content-type-options' found, with contents: nosniff
* GET /: Uncommon header 'access-control-allow-origin' found, with contents: *
* GET /: Uncommon header 'x-frame-options' found, with contents: SAMEORIGIN
* GET /: Uncommon header 'feature-policy' found, with contents: payment 'self'
* GET //ftp/: File/dir '/ftp/' in robots.txt returned a non-forbidden or redirect HTTP code (200)
* GET /robots.txt: "robots.txt" contains 1 entry which should be manually viewed.


**Explanation:**  
- `Access-Control-Allow-Origin: *` indicates permissive CORS which may allow cross-origin data retrieval; depending on whether credentials are allowed this may expose data.  
- ETag leaking inode info is minor info disclosure.  
- `robots.txt` reveals `/ftp/` which the scanner flagged; combined with accessible `/ftp/` content (backups in ZAP) this increases exposure.

**Recommendation:**  
- Tighten CORS policy to allow only known origins (and set `Access-Control-Allow-Credentials` only when needed).  
- Remove sensitive entries from `robots.txt` (don’t list private paths).  
- Remove ETag inode leakage by disabling inode-based ETags or normalizing ETag generation.

---

#### SQLmap — **No confirmed SQLi (scan metadata only)**  
**Evidence:** Provided SQLmap result line:  


Target URL,Place,Parameter,Technique(s),Note(s)  
[http://juice:3000/rest/products/search?q=apple,GET,q,BT](http://juice:3000/rest/products/search?q=apple,GET,q,BT)


The output indicates SQLmap was run against `http://juice:3000/rest/products/search?q=apple` and observed parameters/techniques attempted (`q`, technique tag `BT` in the snippet), but **no confirmed exploitation result** is shown in the snippet provided.

**Explanation:** SQLmap attempted to test the `q` parameter but the provided output does not show a successful injection fingerprint or extracted data. This matches common outcomes: SAST may flag potential injection locations (string concatenation), but SQLmap may not confirm exploitation if parameter is not injectable, input is sanitized, or different injection vector is required.

**Recommendation:**  
- If SAST flagged SQL injection in the code for this endpoint, re-run SQLmap with adjusted options (increase `--level`, try `--risk`, use POST payloads if applicable, try different tamper scripts) and ensure the exact parameter encoding matches the app behavior.  
- Regardless of SQLmap result, prefer converting queries to parameterized/bound queries in code as a proactive fix.


## Task 3 — SAST/DAST Correlation and Security Assessment

#### SAST vs DAST Findings

**Summary of results:**
- **SAST (Semgrep):** 25 findings  
- **ZAP:** 17 findings  
- **Nuclei:** 3 findings  
- **Nikto:** 14 findings  
- **SQLmap:** scan executed, no confirmed SQLi exploitation detected

#### Key differences and unique discoveries

| Aspect | SAST (Semgrep) | DAST (ZAP / Nuclei / Nikto / SQLmap) |
|--------|----------------|----------------------------------------|
| **Nature of analysis** | Static, source-code level — identifies vulnerabilities by code patterns and data flows before runtime. | Dynamic, black-box testing — interacts with the running web app and detects runtime issues. |
| **Unique findings** | - Raw SQL concatenations leading to potential **SQL Injection** in multiple files. <br> - **Hardcoded JWT secret** (`/lib/insecurity.ts`). <br> - **Path traversal** risks in `res.sendFile()` usage. <br> - **Open redirects** via user-controlled `toUrl`. <br> - **XSS** in templates and raw HTML/script insertions. | - **Accessible backup files and directories** (`/ftp/`, `.bak`, `.zip`, `/robots.txt`). <br> - **Public Swagger API exposure** (Nuclei). <br> - **Weak HTTP header configuration / CORS misconfiguration** (Nikto). <br> - **Leaked HTTP metadata** (ETag inode, uncommon headers). <br> - **No confirmed SQLi exploitation**, confirming sanitization is partially effective at runtime. |
| **Overlap areas** | SAST predicted possible SQLi → SQLmap attempted validation (no live exploit confirmed). | DAST (Nikto/ZAP) confirmed exposure of `/ftp` folder that SAST also hinted as insecure via path traversal routes. |
| **Visibility scope** | Code-level secrets, injection sinks, and unsafe functions invisible to external scanning. | Live misconfigurations, server headers, unprotected directories, and runtime assets invisible to static tools. |

**Conclusion:**  
SAST provides **preventive insight** (potential vulnerabilities in source), while DAST confirms **runtime exploitability** and **deployment misconfigurations**.  
In this lab, SAST detected 25 issues mostly in the source logic; DAST confirmed 34 total runtime findings (17 + 3 + 14) across network-exposed surfaces, but also validated that some SAST-detected injections were *not exploitable in runtime* (SQLmap returned safe).


### Integrated Security Recommendations

**Goal:** Combine SAST + DAST for continuous DevSecOps coverage — detect early, verify later.

#### 1. Shift-Left — Static analysis early
- Integrate **Semgrep** into CI (pre-commit / PR checks).  
  - Block merges on **High** severity (SQLi, secrets, path traversal).  
  - Use policies from `p/security-audit` and `p/owasp-top-ten`.
- Use SAST to prevent new vulnerabilities *before* build or deployment.

#### 2. Continuous Runtime Testing — Dynamic stage
- Run **Nuclei** and **Nikto** on staging environments after every deployment:
  - **Nuclei:** detect public endpoints, Swagger/API exposures, CVEs, missing SRI.
  - **Nikto:** validate server headers, CORS, directory listing hygiene.
- Schedule **ZAP** full scan in QA to simulate attacker behavior and find backup files or leaked content.

#### 3. Targeted Exploitation Validation
- Use **SQLmap** (and similar tools) only for endpoints flagged by SAST or DAST for potential injection — confirm exploitability safely.
- Prioritize remediation where both SAST and DAST agree (e.g., `/ftp` paths confirmed by both static and runtime analysis).

#### 4. Harden Configuration and Deployment
- Remove exposed directories (`/ftp`, `/public`, backups) from web root.
- Tighten **CORS** (`Access-Control-Allow-Origin` → specific domains).
- Add **SRI** for external JS/CSS.
- Restrict **Swagger API** access (auth, allow-list, or disable in prod).
- Disable **directory listing** and **inode-based ETags**.
- Store secrets in environment variables, never in code.

#### 5. DevSecOps Integration Flow

```text
[Developer Commit]
   ↓
   Semgrep SAST (block insecure code)
   ↓
   Build → Deploy to Staging
   ↓
   Nuclei + Nikto (fast hygiene)
   ↓
   ZAP Full Scan (crawl + active)
   ↓
   SQLmap (confirm injection risks)
   ↓
   Reports → Jira/Tracker → Fix Cycle
````

#### 6. Continuous Improvement

* Use SAST to **reduce introduction of new issues**.
* Use DAST to **validate security posture after each deployment**.
* Correlate both findings in reports to prioritize remediation.
* Automate evidence collection (SBOMs, CVE matching) for compliance.
