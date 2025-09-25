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
- Run command used: `docker run -d --name juice-shop -p 127.0.0.1:3000:3000 bkimminich/juice-shop:v19.0.0`
- Access URL: http://127.0.0.1:3000
- Network exposure: 127.0.0.1 only [+] Yes  [ ] No  (explain if No)

## Health Check
- Page load: attach screenshot of home page (path or embed)
![asset](/assets/lab1/image.png)
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

- Login/Registration visible: [+] Yes  [ ] No — notes: Login on the left upper corner.
- Product listing/search present: [+] Yes  [ ] No — notes: The listing and a search bar on index page.
- Admin or account area discoverable: [+] Yes  [ ] No — notes: There is no direct link, but there probably is at the direct URL `/administration`.
- Client-side errors in console: [+] Yes  [ ] No — notes: 400 Bad Request.
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
1) No backend user validation. [Issue](https://github.com/projacktor/F25-DevSecOps-Intro/issues/3)
2) No **Security headers** allows XSS attacks. [Issue](https://github.com/projacktor/F25-DevSecOps-Intro/issues/2)
3) No `OPTIONS` requests and CORS policy [Issue](https://github.com/projacktor/F25-DevSecOps-Intro/issues/4)
