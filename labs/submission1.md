# Triage Report — OWASP Juice Shop

## Scope & Asset
- Asset: OWASP Juice Shop (local lab instance)
- Image: bkimminich/juice-shop:19.0.0
- Release link/date: https://github.com/juice-shop/juice-shop/releases/tag/v19.0.0 — Sep 4, 2025
- Image digest (optional): sha256:babfd4e9685b71f3da564cb35f02e870d3dc7d0f444954064bff4bc38602af6b

## Environment
- Host OS: Ubuntu 24.04
- Docker: 28.4.0

## Deployment Details
- Run command used: `docker run -d --name juice-shop -p 127.0.0.1:3000:3000 bkimminich/juice-shop:19.0.0`
- Access URL: http://127.0.0.1:3000
- Network exposure: 127.0.0.1 only [+] Yes  [ ] No  (explain if No)

## Health Check
- Page load: attach screenshot of home page (path or embed)
- API check: first 5–10 lines from `curl -s http://127.0.0.1:3000/rest/products | head`
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
- Login/Registration visible: [+] Yes  [ ] No — notes: Login button on the upper left corner
- Product listing/search present: [+] Yes  [ ] No — notes: The list of products is on the main page, there is a search bar
- Admin or account area discoverable: [+] Yes  [ ] No — notes: There is no direct link, but there probably is at the direct URL `/administration`
- Client-side errors in console: [+] Yes  [ ] No — notes: 400 Bad Request
- Security headers (quick look — optional): `curl -I http://127.0.0.1:3000` → CSP/HSTS present? notes: No, because headers undefined

```
XHR GET
http://127.0.0.1:3000/api/Addresss/null
[HTTP/1.1 400 Bad Request 5ms]

Object { headers: {…}, status: 400, statusText: "Bad Request", url: "http://127.0.0.1:3000/api/Addresss/null", ok: false, type: undefined, redirected: undefined, name: "HttpErrorResponse", message: "Http failure response for http://127.0.0.1:3000/api/Addresss/null: 400 Bad Request", error: {…} }
​
error: Object { status: "error", data: "Malicious activity detected." }
​
headers: Object { headers: undefined, normalizedNames: Map(0), lazyInit: lazyInit()
, … }
​
message: "Http failure response for http://127.0.0.1:3000/api/Addresss/null: 400 Bad Request"
​
name: "HttpErrorResponse"
​
ok: false
​
redirected: undefined
​
status: 400
​
statusText: "Bad Request"
​
type: undefined
​
url: "http://127.0.0.1:3000/api/Addresss/null"
​
<prototype>: Object { … }
```

## Risks Observed (Top 3)
1) The application works over **HTTP**, so it allows for a man-in-the-middle attack.
2) No **Security headers** allows XSS attacks.
3) Configure proper **error handling** to prevent information disclosure URL