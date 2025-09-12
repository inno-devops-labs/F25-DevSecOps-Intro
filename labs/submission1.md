# Triage Report — OWASP Juice Shop

## Scope & Asset
- Asset: OWASP Juice Shop (local lab instance)
- Image: bkimminich/juice-shop
- Release link/date: https://github.com/juice-shop/juice-shop/releases/tag/v19.0.0 — 04.09.2025

## Environment
- Host OS: Arch linux
- Docker: 28.3.0

## Deployment Details
- Run command used: `docker run -d --name juice-shop -p 127.0.0.1:3000:3000 bkimminich/juice-shop:19.0.0`
- Access URL: http://127.0.0.1:3000
- Network exposure: 127.0.0.1 only [X] Yes  [ ] No  (explain if No)

## Health Check
- Page load: attach screenshot of home page (path or embed)
![Justic Shop screenshot](/JuiceShop.png?raw=true "Juice Shop screenshot")
- API check: first 5–10 lines from `curl -s http://127.0.0.1:3000/rest/products | head` // /rest/products returns error, I used /api/products
```json
{"status":"success","data":[{"id":1,"name":"Apple Juice (1000ml)","description":"The all-time classic.","price":1.99,"deluxePrice":0.99,"image":"apple_juice.jpg","createdAt":"2025-09-12T12:00:56.851Z","updatedAt":"2025-09-12T12:00:56.851Z","deletedAt":null},{"id":2,"name":"Orange Juice (1000ml)","description":"Made from oranges hand-picked by Uncle Dittmeyer.","price":2.99,"deluxePrice":2.49,"image":"orange_juice.jpg","createdAt":"2025-09-12T12:00:56.851Z","updatedAt":"2025-09-12T12:00:56.851Z","deletedAt":null},{"id":3,"name":"Eggfruit Juice (500ml)","description":"Now with even more exotic flavour.","price":8.99,"deluxePrice":8.99,"image":"eggfruit_juice.jpg","createdAt":"2025-09-12T12:00:56.851Z","updatedAt":"2025-09-12T12:00:56.851Z","deletedAt":null},{"id":4,"name":"Raspberry Juice (1000ml)","description":"Made from blended Raspberry Pi, water and sugar.","price":4.99,"deluxePrice":4.99,"image":"raspberry_juice.jpg","createdAt":"2025-09-12T12:00:56.851Z","updatedAt":"2025-09-12T12:00:56.851Z","deletedAt":null},{"id":5,"name":"Lemon Juice (500ml)","description":"Sour but full of vitamins.","price":2.99,"deluxePrice":1.99,"image":"lemon_juice.jpg","createdAt":"2025-09-12T12:00:56.852Z","updatedAt":"2025-09-12T12:00:56.852Z","deletedAt":null},{"id":6,"name":"Banana Juice (1000ml)","description":"Monkeys love it the most.","price":1.99,"deluxePrice":1.99,"image":"banana_juice.jpg","createdAt":"2025-09-12T12:00:56.852Z","updatedAt":"2025-09-12T12:00:56.852Z","deletedAt":null},{"id":7,"name":"OWASP Juice Shop T-Shirt","description":"Real fans wear it 24/7!","price":22.49,"deluxePrice":22.49,"image":"fan_shirt.jpg","createdAt":"2025-09-12T12:00:56.852Z","updatedAt":"2025-09-12T12:00:56.852Z","deletedAt":null},{"id":8,"name":"OWASP Juice Shop CTF Girlie-Shirt","description":"For serious Capture-the-Flag heroines only!","price":22.49,"deluxePrice":22.49,"image":"fan_girlie.jpg","createdAt":"2025-09-12T12:00:56.852Z","updatedAt":"2025-09-12T12:00:56.852Z","deletedAt":null},{"id":9,"name":"OWASP SSL Advanced Forensic Tool (O-Saft)","description":"O-Saft is an easy to use tool to show information about SSL certificate and tests the SSL connection according given list of ciphers and various SSL configurations. <a href=\"https://www.owasp.org/index.php/O-Saft\" target=\"_blank\">More...</a>","price":0.01,"deluxePrice":0.01,"image":"orange_juice.jpg","createdAt":"2025-09-12T12:00:56.853Z","updatedAt":"2025-09-12T12:00:56.853Z","deletedAt":null},
```

## Surface Snapshot (Triage)
- Login/Registration visible:  [X] Yes  [ ] No
- Product listing/search present: [X] Yes  [ ] No — notes: substring search
- Admin or account area discoverable: [X] Yes  [ ] No — notes: account area discoverable, didn't find admin
- Client-side errors in console: [X] Yes  [ ] No — notes: Uncaught TypeError: can't access property "initialise", window.cookieconsent is undefined
- Security headers (quick look — optional): `curl -I http://127.0.0.1:3000` → CSP/HSTS present? notes: not present

## Risks Observed (Top 3)
1) jwt used for login, voulnerabilities could be found
didn't find anything else
