# Triage Report — OWASP Juice Shop

## Scope & Asset
- Asset: OWASP Juice Shop (local lab instance)
- Image: bkimminich/juice-shop:19.0.0
- Release link/date: https://github.com/juice-shop/juice-shop/releases/tag/v19.0.0 — 04.09.2025
- Image digest (optional): sha256:547bd3fef4a6d7e25e131da68f454e6dc4a59d281f8793df6853e6796c9bbf58

## Environment
- Host OS: Arch Linux
- Docker: 28.3.3

## Deployment Details
- Run command used: `docker run -d --name juice-shop -p 127.0.0.1:3000:3000 bkimminich/juice-shop:v19.0.0`
- Access URL: http://127.0.0.1:3000
- Network exposure: 127.0.0.1 only [+] Yes  [ ] No  (explain if No)

## Health Check
- Page load: attach screenshot of home page (path or embed)
![asset](/assets/lab1/image.png)
- API check: first 5–10 lines from `curl -s http://127.0.0.1:3000/rest/products | head`
(The command `curl -s http://127.0.0.1:3000/rest/products | head` give me error, but `curl -s http://127.0.0.1:3000/api/products | head` works for me. Result is below)
{"status":"success","data":
[{"id":1,"name":"Apple Juice (1000ml)","description":"The all-time classic.","price":1.99,"deluxePrice":0.99,"image":"apple_juice.jpg","createdAt":"2025-09-15T12:28:45.139Z","updatedAt":"2025-09-15T12:28:45.139Z","deletedAt":null},
{"id":2,"name":"Orange Juice (1000ml)","description":"Made from oranges hand-picked by Uncle Dittmeyer.","price":2.99,"deluxePrice":2.49,"image":"orange_juice.jpg","createdAt":"2025-09-15T12:28:45.139Z","updatedAt":"2025-09-15T12:28:45.139Z","deletedAt":null},
{"id":3,"name":"Eggfruit Juice (500ml)","description":"Now with even more exotic flavour.","price":8.99,"deluxePrice":8.99,"image":"eggfruit_juice.jpg","createdAt":"2025-09-15T12:28:45.139Z","updatedAt":"2025-09-15T12:28:45.139Z","deletedAt":null},
{"id":4,"name":"Raspberry Juice (1000ml)","description":"Made from blended Raspberry Pi, water and sugar.","price":4.99,"deluxePrice":4.99,"image":"raspberry_juice.jpg","createdAt":"2025-09-15T12:28:45.139Z","updatedAt":"2025-09-15T12:28:45.139Z","deletedAt":null},
{"id":5,"name":"Lemon Juice (500ml)","description":"Sour but full of vitamins.","price":2.99,"deluxePrice":1.99,"image":"lemon_juice.jpg","createdAt":"2025-09-15T12:28:45.140Z","updatedAt":"2025-09-15T12:28:45.140Z","deletedAt":null}

## Surface Snapshot (Triage)
- Login/Registration visible: [+] Yes  [ ] No — notes: <...>
- Product listing/search present: [+] Yes  [ ] No — notes: <...>
- Admin or account area discoverable: [+] Yes  [ ] No — notes: <...>
- Client-side errors in console: [+] Yes  [ ] No — notes: <...>
- Security headers (quick look — optional): `curl -I http://127.0.0.1:3000` → CSP/HSTS present? notes: No, no Content-Security-Policy and Strict-Transport-Security headers

## Risks Observed (Top 3)
1) The absence of security headers makes the site vulnerable to XSS attacks: [Issue](https://github.com/ilyalinhnguyen/F25-DevSecOps-Intro/issues/2)
2) Using the HTTP protocol, lack of encryption (No CSP, HSTS): [Issue](https://github.com/ilyalinhnguyen/F25-DevSecOps-Intro/issues/3)
3) SQL injection: [Issue](https://github.com/ilyalinhnguyen/F25-DevSecOps-Intro/issues/4)
