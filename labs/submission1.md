# Triage Report — OWASP Juice Shop

---
Alexander Rozanov / CBS-02 / al.rozanov@innopolis.university
---

## Scope & Asset
- Asset: OWASP Juice Shop (local lab instance)
- Image: bkimminich/juice-shop:v19.0.0
- Release link/date: https://hub.docker.com/layers/bkimminich/juice-shop/v19.0.0/images/sha256-547bd3fef4a6d7e25e131da68f454e6dc4a59d281f8793df6853e6796c9bbf58 — Sep 4, 2025
- Image digest: <sha256:547bd3fef4a6d7e25e131da68f454e6dc4a59d281f8793df6853e6796c9bbf58>

## Environment
- Host OS: Arch - 257.4-1-arch
- Docker: Docker version 28.2.2, build e6534b4

## Deployment Details
- Run command used: `docker run -d --name juice-shop -p 127.0.0.1:3000:3000 bkimminich/juice-shop:v19.0.0`
- Access URL: http://127.0.0.1:3000
- Network exposure: 127.0.0.1

## Health Check
- Page load: ![home page of juice-shop site](/labs/assets/home_page.png)
- API check: `curl -s http://127.0.0.1:3000/rest/products | head`
```html
<html>
  <head>
    <meta charset='utf-8'>
    <title>Error: Unexpected path: /rest/products</title>
    <style>* {
  margin: 0;
  padding: 0;
  outline: 0;
}
```

## Surface Snapshot (Triage)
- Login/Registration visible: [+] Yes
- Product listing/search present: [+] Yes
- Admin or account area discoverable: [+] Yes
- Client-side errors in console: [+] Yes
- Security headers: `curl -I http://127.0.0.1:3000` [-] No


## Risks Observed (Top 3)
1) **SQL Injection (UNION-based) — /rest/products/search**
   - **Endpoint/Field:** `GET /rest/products/search?q=<term>`
   - **Payload (worked):**
     `1')) UNION SELECT 1,2,3,4,5,6,7,8,sqlite_version();--`
   - **Evidence:** server returns fields populated from the injected `UNION SELECT` including `sqlite_version()`
   ![sqli](/labs/assets/sqli.png)
   - **Impact:** Extraction/manipulation of database data; schema enumeration; potential pivoting to full compromise.
   - **Likelihood:** High (no auth required; trivial payload).
   - **Overall Risk:** **High**
   - **Remediation:** Use parameterized queries/prepared statements; avoid string concatenation; validate `q` against a strict allow-list; consider temporary WAF rules; add negative tests in CI.

2) **Reflected XSS — /#/search**
   - **Endpoint/Field:** Client-side search page `/#/search?q=<term>`
   - **Payload (worked):**
     `"<iframe src="javascript:alert(\xss\)">`
     (URL-encoded in PoC)
   - **Evidence:** JavaScript `alert('xss')` executes on page load
   ![xss](/labs/assets/xss.png)
   - **Impact:** Session/token theft, UI phishing, actions performed in victim’s context.
   - **Likelihood:** medium (reachable anonymously; simple payload).
   - **Overall Risk:** **Medium**
   - **Remediation:** Context-aware output encoding (DOM/HTML/URL); avoid injecting raw HTML into the DOM; validate/normalize input; deploy a strict Content Security Policy (CSP); add XSS test cases.

3) **Server-Side Template Injection (SSTI) — /profile (Username)**
   - **Endpoint/Field:** `/profile` → **Username**
   - **Payload (worked):** `a#{7*7}`
   - **Evidence:** Rendered value evaluates to `a49`, confirming expression execution in the template engine
   ![SSTI](/labs/assets/SSTI.png)
   - **Impact:** Depending on engine: template sandbox escape, reading sensitive data, possible remote code execution.
   - **Likelihood:** Medium–High (requires authenticated user; easy to reproduce).
   - **Overall Risk:** **High**
   - **Remediation:** Escape/sanitize user input before rendering; disable expression evaluation for untrusted data; enforce allow-list for Username; isolate/sandbox the template engine; add negative tests.

## Next Actions / Backlog

- [ ] **Issue:** Parameterize product search (SQLi) — [`#1`](https://github.com/Rozanalex/F25-DevSecOps-Intro/issues/1)
  - **Labels:** `security`
  - **Context:** `GET /rest/products/search?q=` is vulnerable to UNION-based SQLi.
  - **Tasks:**
    - Replace any string-concatenated SQL with **prepared statements/parameterized queries**.
    - Add strict **allow-list validation** for `q` (length, charset, pattern).
    - Add **negative tests** (failing payloads) to CI.
  - **DoD:** payload `1')) UNION SELECT ...` no longer affects the response; unit/integration tests proving rejection; code reviewed.

- [ ] **Issue:** Mitigate reflected XSS in search — [`#2`](https://github.com/Rozanalex/F25-DevSecOps-Intro/issues/2)
  - **Labels:** `security`
  - **Context:** `/#/search?q=` reflects untrusted input into the DOM.
  - **Tasks:**
    - Apply **context-aware output encoding**; avoid inserting raw HTML.
    - Add **CSP** (report-only first, then enforcing) to reduce script injection impact.
    - Add **XSS regression tests** with the PoC payload.
  - **DoD:** PoC `"<iframe src="javascript:alert('xss')">` (URL-encoded) no longer executes; CSP present and logged; tests in CI.

- [ ] **Issue:** Prevent SSTI in Username rendering — [`#3`](https://github.com/Rozanalex/F25-DevSecOps-Intro/issues/3)
  - **Labels:** `security`
  - **Context:** `a#{7*7}` in **Username** evaluates server-side to `a49`.
  - **Tasks:**
    - Treat all template variables as **data**, not expressions (escape by default).
    - **Disable expression evaluation** for untrusted fields / switch to a safe render API.
    - Enforce **allow-list** for Username (length + safe chars).
    - Add tests with `a#{7*7}` and similar probes.
  - **DoD:** `a#{7*7}` rendered literally; tests pass; code review completed.
