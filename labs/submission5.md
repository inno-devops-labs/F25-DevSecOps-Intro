## Lab 5 — SAST & DAST Analysis (OWASP Juice Shop v19.0.0)

### Task 1 — SAST with Semgrep (counts & key findings)
Total findings: see `labs/lab5/analysis/sast-analysis.txt` (25)

- Top 5 SAST findings (file → issue → severity):
  - `routes/search.ts` → concatenated criteria in SQL query (sequelize) → High (SQLi)
  - `routes/login.ts` → SQL built with user input (email/password) → High (SQLi)
  - `routes/fileServer.ts` → `res.sendFile` with user‑controlled path → High (Path Traversal)
  - `routes/redirect.ts` → open redirect via unvalidated `toUrl` → Medium (Open Redirect)
  - `lib/insecurity.ts` → hardcoded secret used for JWT signing → High (Hardcoded Secret)

Semgrep detection capabilities & coverage:
- Rulepacks used: `p/security-audit` and `p/owasp-top-ten`.
- Detected categories in this codebase:
  - SQL injection in raw/concatenated Sequelize queries (`routes/search.ts`, `routes/login.ts`, multiple codefix files).
  - Path traversal via `res.sendFile` with user-controlled input (`fileServer.ts`, `keyServer.ts`, `logfileServer.ts`, `quarantineServer.ts`).
  - Open redirect via unvalidated `toUrl` (`redirect.ts`).
  - Hardcoded secret usage in JWT context (`lib/insecurity.ts`).
  - Unsafe templating/DOM usage (unquoted attributes, potential XSS) in Angular templates and views.
  - Directory listing enabled in Express router configuration (`server.ts`).
- Strengths observed: fast scans, actionable rule messages with links, good coverage of common injection and Express/Sequelize patterns; easy CI integration.
- Gaps/limitations: static analysis won’t assess runtime headers/CORS/auth flows; framework-specific patterns may miss custom abstractions; potential false positives where inputs are validated elsewhere.

### Task 2 — DAST with multiple tools
Counts summary from `labs/lab5/analysis/dast-analysis.txt`:
- ZAP: 15
- Nuclei: 21
- Nikto: 14
- SQLmap: results under `labs/lab5/sqlmap/`

Significant example per tool:
- ZAP (`labs/lab5/zap/zap-report.json`):
  - Backup File Disclosure (riskcode 2)
  - CORS Misconfiguration (riskcode 2)
  - Bypassing 403 (riskcode 2)
- Nuclei (`labs/lab5/nuclei/nuclei-results.json`):
  - Public Swagger API detected at `/api-docs/swagger.yaml` (exposure)
  - Missing security headers (e.g., HSTS, Permissions‑Policy, Referrer‑Policy)
  - Missing Subresource Integrity on external assets
- Nikto (`labs/lab5/nikto/nikto-results.txt`):
  - Server leaks inodes via ETags
  - `robots.txt` exposes `/ftp/`; `/ftp/`, `/public/`, `/css/` interesting
  - Permissive `Access-Control-Allow-Origin: *` observed
- SQLmap (`labs/lab5/sqlmap/localhost/log`, `results-*.csv`):
  - Injection point confirmed: `GET /rest/products/search?q=apple`
  - Techniques: boolean‑based blind; time‑based blind
  - Payload example (from log): `q=apple%' AND 8176=8176 AND 'GumB%'='GumB`
  - Back‑end DBMS identified: SQLite

Tool effectiveness & strengths (observed):
- **ZAP**: broad web app coverage and useful categorizations; good for auth/session/CORS/header issues.
- **Nuclei**: fast detection of known misconfigurations/templates (APIs, headers, SRI) with minimal setup.
- **Nikto**: server/config exposure and directory hints that aid manual exploration.
- **SQLmap**: deep confirmation and exploitation detail for SQLi once a candidate endpoint is known.

### Task 3 — SAST/DAST Correlation
- Counts overview: see `labs/lab5/analysis/correlation.txt` (SAST 25, ZAP 15, Nuclei 21, Nikto 14).
- Clear correlations:
  - SQL Injection: SAST flags raw SQL in `routes/search.ts`; SQLmap confirms exploitable SQLi on the corresponding search endpoint (`/rest/products/search?q=...`).
  - Directory/Files exposure: SAST shows directory listing in `server.ts` (`/ftp`, `/logs`, `/encryptionkeys`); Nikto reports accessible `/ftp/` and `robots.txt` entry for `/ftp/`.
  - Headers/CORS: ZAP and Nuclei report missing/misconfigured security headers and permissive CORS; aligns with runtime config not enforced by code.

Integrated recommendations (DevSecOps pipeline):
- Prevent SQLi: replace string‑built queries with parameterized Sequelize queries; add validation on search inputs; add automated checks (Semgrep CI rule set) to block PRs introducing raw concatenated SQL.
- Path traversal: canonicalize and validate filenames before `res.sendFile`; restrict to allow‑listed directories; add tests to ensure traversal attempts are blocked.
- Open redirect: enforce allow‑list for redirect targets; add unit tests for `toUrl` validation.
- Reduce information disclosure: disable directory listing for sensitive routes; ensure `robots.txt` does not expose administrative paths in production.
- Strengthen headers and CORS: adopt secure defaults (HSTS, CORP/COEP/CSP/Permissions‑Policy/Referrer‑Policy); restrict `Access-Control-Allow-Origin` to trusted origins.
- Process integration: run Semgrep on PRs; run ZAP baseline in CI against preview/staging; run Nuclei regularly with curated templates; use Nikto for server hardening checks post‑deploy; reserve SQLmap for targeted testing when indicators suggest DB risks.

### Evidence pointers
- SAST counts: `labs/lab5/analysis/sast-analysis.txt`
- DAST counts: `labs/lab5/analysis/dast-analysis.txt`
- SAST detailed: `labs/lab5/semgrep/semgrep-report.txt`
- ZAP: `labs/lab5/zap/zap-report.json`
- Nuclei: `labs/lab5/nuclei/nuclei-results.json`
- Nikto: `labs/lab5/nikto/nikto-results.txt`
- SQLmap: `labs/lab5/sqlmap/localhost/log`, `labs/lab5/sqlmap/results-*.csv`


