# Triage Report — OWASP Juice Shop

## Scope & Asset
- Asset: OWASP Juice Shop (local lab instance)
- Image: bkimminich/juice-shop:19.0.0
- Release link/date: https://github.com/juice-shop/juice-shop/releases/tag/v19.0.0 — Sep 4, 2025
- Image digest (optional): sha256:babfd4e9685b71f3da564cb35f02e870d3dc7d0f444954064bff4bc38602af6b

## Environment
- Host OS: macOS 15.6.1
- Docker: 27.4.0

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
  margin: 0;
  padding: 0;
  outline: 0;
}
```

## Surface Snapshot (Triage)
- Login/Registration visible: [+] Yes  [ ] No — notes: Login button on the upper left corner
- Product listing/search present: [+] Yes  [ ] No — notes: The list of products is on the main page, there is a search bar
- Admin or account area discoverable: [+] Yes  [ ] No — notes: There is no direct link, but there probably is at the direct URL /administration
- Client-side errors in console: [+] Yes  [ ] No — notes: 400 Bad Request
- Security headers (quick look — optional): `curl -I http://127.0.0.1:3000` → CSP/HSTS present? notes: No, because there aren't headers

## Risks Observed (Top 3)
1) **Lack of HTTPS** — The application works over HTTP, which allows for a man-in-the-middle attack and interception of data.
2) **Absence of Security Headers** — This may allow for XSS attacks or clickjacking.
3) **The presence of public registration and login** is the entry point for brute force attacks.
