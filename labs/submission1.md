# Triage Report — OWASP Juice Shop

## Scope & Asset
- Asset: OWASP Juice Shop (local lab instance)
- Image: bkimminich/juice-shop:19.0.0
- Release link/date: https://github.com/juice-shop/juice-shop/releases/tag/v19.0.0 — Sep 4, 2025
- Image digest (optional): <sha256:2765a26de7647609099a338d5b7f61085d95903c8703bb70f03fcc4b12f0818d>

## Environment
- Host OS: <Ubuntu 22.04>
- Docker: <28.4.0>


## Deployment Details
- Run command used: `docker run -d --name juice-shop -p 127.0.0.1:3000:3000 bkimminich/juice-shop:v19.0.0`
- Access URL: http://127.0.0.1:3000
- Network exposure: 127.0.0.1 only [X] Yes  [ ] No  (explain if No)

## Health Check
- Page load: attach screenshot of home page (path or embed) : ![homepage](/labs/sub1/homepage.png)
- API check: first 5–10 lines from `curl -s http://127.0.0.1:3000/rest/products | head`:


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
- Login/Registration visible: [X] Yes  [ ] No — notes: Account button and then login button in the top right corner
- Product listing/search present: [X] Yes  [ ] No — notes: Magnifying glass button in the top right corner
- Admin or account area discoverable: [X] Yes  [ ] No — notes: After registering and clicking to button with your nickname in the top right corner there is your User Profile 
- Client-side errors in console: [X] Yes  [ ] No — notes: When you not loged in if you click to 'Apple Pomace' and after there is a button 'sent back to us' there are a lot of errors in console
- Security headers (quick look — optional): `curl -I http://127.0.0.1:3000` → CSP/HSTS present? notes: HSTS and CSP headers are missing.

## Risks Observed (Top 3)
1) Insufficient Input Validation — Forms and search fields lack strong server-side validation, creating clear vectors for injection attacks.
2) Sensitive Information Disclosure — Detailed error messages (e.g., HTTP 500) and informational headers (e.g., X-Recruiting) expose internal app structure and potential attack surfaces.
3) Missing Security Hardening Headers — Absence of CSP and HSTS headers increases exposure to client-side attacks like XSS and man-in-the-middle exploits.


## Follow-up Actions


- [#1](https://github.com/username/repo/issues/1) Add security headers (CSP, HSTS) 
- [#2](https://github.com/username/repo/issues/2) Implement input validation for all user inputs
- [#3](https://github.com/username/repo/issues/3) Configure proper error handling to prevent information disclosure

*Note: Issues labeled as `backlog` in the repository*