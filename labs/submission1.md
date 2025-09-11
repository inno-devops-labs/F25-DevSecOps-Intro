# Triage Report — OWASP Juice Shop

## Scope & Asset
- Asset: OWASP Juice Shop
- Image: bkimminich/juice-shop
- Release link/date: https://github.com/juice-shop/juice-shop/releases/tag/v19.0.0 — September 4, 2025
- Image digest: sha256:c6f965f8929c2c43676e3ac55cd19d482c0084400195db07ed7513a04f3468b5
## Environment
- Host OS: Ubuntu 24.04
- Docker: 26.1.3

## Deployment Details
- Run command used: `docker run -d --name juice-shop -p 127.0.0.1:3000:3000 bkimminich/juice-shop
- Access URL: http://127.0.0.1:3000
- Network exposure: 127.0.0.1 only [✅] Yes  [ ] No 

## Health Check
- Page load: <img width="1218" height="756" alt="Page load" src="https://github.com/user-attachments/assets/2fa6f9fa-5247-42ec-9ef9-109ec1448797" />
- API check: first 5–10 lines from `curl -s http://127.0.0.1:3000/rest/products | head`  <img width="674" height="223" alt="curl -s" src="https://github.com/user-attachments/assets/808b818f-294f-41b6-8476-d73310fc0ff5" />

## Surface Snapshot (Triage)
- Login/Registration visible: [✅] Yes  [ ] No — notes: The login and registration forms are available in the upper right corner by clicking the Account button.
- Product listing/search present: [✅] Yes  [ ] No — notes: The product catalog with search is visible on the main page.
- Admin or account area discoverable: [✅] Yes  [ ] No — notes: Navigation to account sections (Orders & Payment, Privacy & Security) is visible on hover, but an attempt to access the profile returns 500 Error: Blocked illegal activity. The admin panel is not displayed and is not accessible to the average user.
- Client-side errors in console: [✅] Yes  [ ] No — notes: An error occurs when trying to add a product to the basket on a registered account: "ERROR TypeError: can't access property "Products", o is null".
- Security headers: `curl -I http://127.0.0.1:3000` → CSP/HSTS present? notes: CSP (Content-Security-Policy) and HTST (Strict-Transport-Security) headers are missing. The absence of CSP and HSTS exposes the application to content injection attacks and SSL stripping vulnerabilities.
	<img width="465" height="374" alt="curl -I" src="https://github.com/user-attachments/assets/e90f6646-752b-472d-b45a-3947c7fad1a8" />


## Risks Observed (Top 3)
1) **Sensitive Data Exposure:** The `dirb` scanning tool exposed sensitive data by accessing the confidential document at `http://127.0.0.1:3000/ftp/acquisitions.md`. https://github.com/flowelx/F25-DevSecOps-Intro/issues/1
2) **DOM XSS:** I injected a malicious `<iframe>` element into the search input, which was executed in the user's browser upon submission, showing reflected DOM-based XSS vulnerability.
3) **Improper Input Validation:** I bypassed the client-side input validation mechanism by manipulating the HTML attributes to submit a zero-star store feedback.

## Related Issues
- [#1. Sensitive Data Exposure](https://github.com/flowelx/F25-DevSecOps-Intro/issues/1)
- [#2. DOM XSS](https://github.com/flowelx/F25-DevSecOps-Intro/issues/2)
- [#3. Improper Input Validation](https://github.com/flowelx/F25-DevSecOps-Intro/issues/3)
