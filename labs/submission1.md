# Triage Report — OWASP Juice Shop

## Scope & Asset
- Asset: OWASP Juice Shop (local lab instance)
- Image: bkimminich/juice-shop:19.0.0
- Release link/date: https://github.com/juice-shop/juice-shop/releases/tag/v19.0.0 — Sep 4, 2025
- Image digest (optional): sha256:2765a26de7647609099a338d5b7f61085d95903c8703bb70f03fcc4b12f0818d

## Environment
- Host OS: Fedora Linux 42
- Docker: 28.3.0

## Deployment Details
- Run command used: `docker run -d --name juice-shop -p 127.0.0.1:3000:3000 bkimminich/juice-shop:19.0.0`
- Access URL: http://127.0.0.1:3000
- Network exposure: 127.0.0.1 only [+] Yes  [ ] No  (explain if No)

## Health Check
- Page load: attach screenshot of home page (path or embed)
- API check: first 5–10 lines from `curl -s http://127.0.0.1:3000/rest/products | head`

```
<html>
  <head>
    <meta charset='utf-8'> 
    <title>Error: Unexpected path: /rest/products</title>
    <style>* {
```


## Surface Snapshot (Triage)
- Login/Registration visible: [+] Yes  [ ] No — notes: Login button on the top panel.
- Product listing/search present: [+] Yes  [ ] No — notes: Search button on navigation bar
- Admin or account area discoverable: [+] Yes  [ ] No — notes: account area is accessible, admin page (only if you logged as admin): http://127.0.0.1:3000/#/administration
- Client-side errors in console: [+] Yes  [ ] No — notes: For example 400 Bad Request when tries add item in basket
- Security headers (quick look — optional): `curl -I http://127.0.0.1:3000` → CSP/HSTS present? notes: No, because there are no headers: Content-Security-Policy, Strict-Transport-Security

## Risks Observed (Top 3)
1) SQL injection - ability to get access to admin user.
2) XSS vulnerability - allows inject malicious scripts into web pages viewed by other users
3) A full error report from the backend can help an attacker understand how the system works.
