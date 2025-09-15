# Triage Report — OWASP Juice Shop

## Scope & Asset
- Asset: OWASP Juice Shop (local lab instance)
- Image: bkimminich/juice-shop:19.0.0
- Release link/date: https://github.com/juice-shop/juice-shop/releases/tag/v19.0.0 — 04.09.2025

## Environment
- Host OS: macOS 15.6.1
- Docker: 4.43.1

## Deployment Details
- Run command used: `docker run -d --name juice-shop -p 127.0.0.1:3000:3000 bkimminich/juice-shop:19.0.0`
- Access URL: http://127.0.0.1:3000
- Network exposure: 127.0.0.1 only [x] Yes  [ ] No  (explain if No)

## Health Check
- Page load: attach screenshot of home page (path or embed)
![Фото](<iimage.png>)
- API check: first 5–10 lines from `curl -s http://127.0.0.1:3000/rest/products | head`
<html>
  <head>
    <meta charset='utf-8'> 
    <title>Error: Unexpected path: /rest/products</title>
    <style>* {
  margin: 0;
  padding: 0;
  outline: 0;
}

## Surface Snapshot (Triage)
- Login/Registration visible: [x] Yes  [ ] No — notes: <...>
- Product listing/search present: [x] Yes  [ ] No — notes: <...>
- Admin or account area discoverable: [ ] Yes  [ ] No — notes: account area is accessible, admin info can be faked or mailfored
- Client-side errors in console: [ ] Yes  [x] No — notes: <...>
- Security headers (quick look — optional): `curl -I http://127.0.0.1:3000` → CSP/HSTS present? no notes: <...>
HTTP/1.1 200 OK
Access-Control-Allow-Origin: *
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Feature-Policy: payment 'self'
X-Recruiting: /#/jobs
Accept-Ranges: bytes
Cache-Control: public, max-age=0
Last-Modified: Mon, 15 Sep 2025 19:37:31 GMT
ETag: W/"124fa-1994ee1e725"
Content-Type: text/html; charset=UTF-8
Content-Length: 75002
Vary: Accept-Encoding
Date: Mon, 15 Sep 2025 20:02:47 GMT
Connection: keep-alive
Keep-Alive: timeout=5

## Risks Observed (Top 3)
1) XSS Vulnerability
Lack of CSP with extensive user input handling (search, forms) enables arbitrary JavaScript execution
2) Information Leakage via Error Messages
Authentication endpoints return overly detailed error responses 
3) Missing Security Headers
Absence of CSP and HTTP HSTS headers increases client-side attacks and man-in-the-middle exploits
