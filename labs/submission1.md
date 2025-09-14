# Triage Report — OWASP Juice Shop

## Scope & Asset
- Asset: OWASP Juice Shop (local lab instance)
- Image: bkimminich/juice-shop:19.0.0
- Release link/date: [Release v19.0.0](https://github.com/juice-shop/juice-shop/releases/tag/v19.0.0) — Sep 4, 2025
- Image digest (optional): sha256:2765a26de7647609099a338d5b7f61085d95903c8703bb70f03fcc4b12f0818d

## Environment
- Host OS: Ubuntu 24.04.3
- Docker: 28.3.3

## Deployment Details
- Run command used: `docker run -d --name juice-shop -p 127.0.0.1:3000:3000 bkimminich/juice-shop:v19.0.0`
- Access URL: http://127.0.0.1:3000
- Network exposure: 127.0.0.1 only. As we run using the command `-p 127.0.0.1:3000:3000`, which makes the resource only local-host accecible. If we used simply `-p 3000:3000`, the app would be reachable from any host in the network

## Health Check
- Page load: ![Main page](/labs/static/MainPage.png)
- API check: 
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
- Login/Registration visible: Yes — notes: the authentication form is accecible and visible
- Product listing/search present: Yes — notes: there is a list of products an the main page
- Admin or account area discoverable: Yes — notes: account options are available after authentiacation
- Client-side errors in console: No — notes: no errors are visible from the client side
- Security headers (quick look — optional): `curl -I http://127.0.0.1:3000` → CSP/HSTS present? notes: no CSP/HSTS headers found

## Risks Observed (Top 3)
1) [CORS header](https://github.com/TovarishDru/F25-DevSecOps-Intro/issues/2): `Access-Control-Allow-Origin: *`. The recources are acessible from any domain, malicious sites may use the API data allowing Cross-Site Request Forgery
2) There is no [CSP header](https://github.com/TovarishDru/F25-DevSecOps-Intro/issues/3) - Cross-Site Scripting may be used. Arbitrary JavaScript injection is possible, the website may hand over the keys to the victim’s session, data, and actions
3) No [HSTS header](https://github.com/TovarishDru/F25-DevSecOps-Intro/issues/4). This allows SSL stripping - downgrading communication from HTTPS to simple HTTP. By adding such header we enforce browser to use only HTTPS and improve the security of user 
