# Triage Report — OWASP Juice Shop

## Scope & Asset
- Asset: OWASP Juice Shop (local lab instance)
- Image: bkimminich/juice-shop:19.0.0
- Release link/date: https://github.com/juice-shop/juice-shop/releases/tag/v19.0.0 — Sep 4, 2025
- Image digest (optional): sha256:2765a26de7647609099a338d5b7f61085d95903c8703bb70f03fcc4b12f0818d

## Environment
- Host OS: Ubuntu 25.04
- Docker: 28.1.1+1

## Deployment Details
- Run command used: `docker run -d --name juice-shop -p 127.0.0.1:3000:3000 bkimminich/juice-shop:19.0.0`
- Access URL: http://127.0.0.1:3000
- Network exposure: 127.0.0.1 only [X] Yes  [ ] No  (explain if No)

## Health Check
- Page load: ![screenshot](/images/lab1/screenshot.png)
- API check: first 5–10 lines from `curl -s http://127.0.0.1:3000/rest/products | head`
```
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
- Login/Registration visible: [x] Yes  [ ] No — notes: In the upper right corner, if you click on the account, you can go to login, and then to registration
- Product listing/search present: [x] Yes  [ ] No — notes: List on the main screen, search next to the account
- Admin or account area discoverable: [x] Yes  [ ] No — notes: Account area via login/register; some demo users visible
- Client-side errors in console: [x] Yes  [ ] No — notes: "ERROR Error: Parameter "key" required"
- Security headers (quick look — optional): `curl -I http://127.0.0.1:3000` → CSP/HSTS present? notes:
  - HSTS: Strict-Transport-Security header missing, HTTPS not enforced
  - CSP: Content-Security-Policy header missing, no CSP rules applied
  - Other headers observed: 
      - X-Content-Type-Options: nosniff
      - X-Frame-Options: SAMEORIGIN
      - Feature-Policy: payment 'self'

## Risks Observed (Top 3)
1) The user's mail is displayed in full in the comments [issue](https://github.com/Darya-Tolmeneva/F25-DevSecOps-Intro/issues/1)
2) Missing HSTS and CSP headers — browser security protections not applied [issue](https://github.com/Darya-Tolmeneva/F25-DevSecOps-Intro/issues/2)
3) Client-side errors in console (Parameter "key" required) — potential vector for exploitation [issue](https://github.com/Darya-Tolmeneva/F25-DevSecOps-Intro/issues/3)
