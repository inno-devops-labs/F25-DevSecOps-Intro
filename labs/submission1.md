# Triage Report — OWASP Juice Shop

## Scope & Asset
- Asset: OWASP Juice Shop (local lab instance)
- Image: bkimminich/juice-shop:19.0.0
- Release link/date: [<link>](https://github.com/juice-shop/juice-shop/releases/tag/v19.0.0) — last week
- Image digest (optional): <sha256:...>

## Environment
- Host OS: Windows 11 Home 24H2
- Docker: 4.46.0

## Deployment Details
- Run command used: `docker run -d --name juice-shop -p 127.0.0.1:3000:3000 bkimminich/juice-shop:19.0.0`
- Access URL: http://127.0.0.1:3000
- Network exposure: 127.0.0.1 only [ ] Yes  [ ] No  (explain if No)

## Health Check
- Page load: attach screenshot of home page (path or embed)
- API check: first 5–10 lines from `curl -s http://127.0.0.1:3000/rest/products | head`

## Surface Snapshot (Triage)
- Login/Registration visible: [ ] Yes  [ ] No — notes: <...>
- Product listing/search present: [ ] Yes  [ ] No — notes: <...>
- Admin or account area discoverable: [ ] Yes  [ ] No — notes: <...>
- Client-side errors in console: [ ] Yes  [ ] No — notes: <...>
- Security headers (quick look — optional): `curl -I http://127.0.0.1:3000` → CSP/HSTS present? notes: <...>

## Risks Observed (Top 3)
1) <risk + 1‑line rationale>
2) <risk + 1‑line rationale>
3) <risk + 1‑line rationale>

