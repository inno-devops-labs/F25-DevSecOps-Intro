# Triage Report — OWASP Juice Shop

## Scope & Asset
- Asset: OWASP Juice Shop (local lab instance)
- Image: bkimminich/juice-shop:v19.0.0
- Release link/date: https://github.com/juice-shop/juice-shop/releases/tag/v19.0.0 — two weeks ago
- Image digest (optional): <sha256:...>

## Environment
- Host OS: Windows 11 Pro 23H2
- Docker: 28.0.4

## Deployment Details
- Run command used: docker run -d --name juice-shop   -p 127.0.0.1:3000:3000  bkimminich/juice-shop:v19.0.0     
- Access URL: http://127.0.0.1:3000
- Network exposure: 127.0.0.1 only [x] Yes  [ ] No  (explain if No)

## Health Check
- Page load: attach screenshot of home page (path or embed)
<img width="2560" height="1440" alt="image" src="https://github.com/user-attachments/assets/87784039-4a8f-4c9f-9aa4-6104cf0b483e" />

- API check: first 5–10 lines from `curl -s http://127.0.0.1:3000/rest/products | head`
curl.exe -s http://127.0.0.1:3000/api/Products | more
{"status":"success","data":
[{"id":1,"name":"Apple Juice (1000ml)","description":"The all-time classic.","price":1.99,"deluxePrice":0.99,"image":"apple_juice.jpg","createdAt":"2025-09-15T12:28:45.139Z","updatedAt":"2025-09-15T12:28:45.139Z","deletedAt":null},
{"id":2,"name":"Orange Juice (1000ml)","description":"Made from oranges hand-picked by Uncle Dittmeyer.","price":2.99,"deluxePrice":2.49,"image":"orange_juice.jpg","createdAt":"2025-09-15T12:28:45.139Z","updatedAt":"2025-09-15T12:28:45.139Z","deletedAt":null},
{"id":3,"name":"Eggfruit Juice (500ml)","description":"Now with even more exotic flavour.","price":8.99,"deluxePrice":8.99,"image":"eggfruit_juice.jpg","createdAt":"2025-09-15T12:28:45.139Z","updatedAt":"2025-09-15T12:28:45.139Z","deletedAt":null},
{"id":4,"name":"Raspberry Juice (1000ml)","description":"Made from blended Raspberry Pi, water and sugar.","price":4.99,"deluxePrice":4.99,"image":"raspberry_juice.jpg","createdAt":"2025-09-15T12:28:45.139Z","updatedAt":"2025-09-15T12:28:45.139Z","deletedAt":null},
{"id":5,"name":"Lemon Juice (500ml)","description":"Sour but full of vitamins.","price":2.99,"deluxePrice":1.99,"image":"lemon_juice.jpg","createdAt":"2025-09-15T12:28:45.140Z","updatedAt":"2025-09-15T12:28:45.140Z","deletedAt":null}


## Surface Snapshot (Triage)
- Login/Registration visible: [x] Yes  [ ] No — notes: <img width="2560" height="1440" alt="image" src="https://github.com/user-attachments/assets/032fe628-4806-4a51-9e71-1735d9c7ce92" />
- Product listing/search present: [x] Yes  [ ] No — notes: <img width="2560" height="1440" alt="image" src="https://github.com/user-attachments/assets/a576b25a-fdf4-4eed-ada9-d2442859e21c" />
- Admin or account area discoverable: [x] Yes  [ ] No — notes: <img width="304" height="115" alt="image" src="https://github.com/user-attachments/assets/4c3234c4-dbe4-46d9-afbb-bbe53da3e220" />
- Client-side errors in console: [ ] Yes  [x] No — notes: <...>
- Security headers (quick look — optional): `curl -I http://127.0.0.1:3000` → CSP/HSTS present? notes: No


## Risks Observed (Top 3)
1) **Return to the previous page works incorrectly (It is possible to get access after an exit)**
2) **HTTP protocol is unencrypted**
3) **Missing Security Headers:**
