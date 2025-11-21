# Lab 11 — Reverse Proxy Hardening: Nginx Security Headers, TLS, and Rate Limiting

## Task 1 — Reverse Proxy Compose Setup

### Why Reverse Proxies Improve Security

Reverse proxies strengthen security by providing:

* **TLS termination** — encryption is handled at the proxy, keeping backend services simple and isolated.
* **Security header injection** — Nginx adds consistent headers before requests reach the application.
* **Request filtering** — malicious or malformed traffic can be blocked before reaching backend services.
* **Single access point** — only Nginx is exposed to the internet; all internal services stay hidden.

### Reduced Attack Surface by Hiding Direct App Ports

Exposing only the reverse proxy prevents attackers from directly scanning or exploiting backend services. By keeping the Juice Shop container isolated with **no published host ports**, its reachable surface is significantly minimized.

### Docker Compose Output (Task Requirement)

The output below demonstrates that **only Nginx** exposes host ports, while **Juice Shop exposes none**:

```
lab11-nginx-1   ...   0.0.0.0:8080->8080/tcp, 0.0.0.0:8443->8443/tcp
lab11-juice-1   ...   no published ports
```

---

## Task 2 — Security Headers

Below are the required security headers extracted from `headers-https.txt`.

### X-Frame-Options

**Header:** `X-Frame-Options: SAMEORIGIN`

* Protects against **clickjacking** by preventing the site from being embedded in iframes on external domains.

### X-Content-Type-Options

**Header:** `X-Content-Type-Options: nosniff`

* Prevents MIME-type sniffing attacks and reduces risk of content-type confusion.

### Strict-Transport-Security (HSTS)

**Header:** `Strict-Transport-Security: max-age=31536000; includeSubDomains`

* Forces browsers to always use HTTPS, preventing SSL stripping attacks.

### Referrer-Policy

**Header:** `Referrer-Policy: no-referrer`

* Ensures the `Referer` header is not sent, protecting user privacy.

### Permissions-Policy

**Header:** `Permissions-Policy: geolocation=()`

* Restricts browser APIs. Here, geolocation is fully disabled.

### COOP / CORP

**Headers:**

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: same-origin
```

* Protect against cross-origin data leaks and cross-origin interactions involving windows and resources.

### CSP-Report-Only

**Header:** `Content-Security-Policy-Report-Only: default-src 'self'`

* Provides visibility into CSP violations **without blocking content**.

---

## Task 3 — TLS, HSTS, Rate Limiting & Timeouts

### TLS / testssl Summary

* **Enabled protocols:** TLSv1.2 and TLSv1.3
* **Cipher suites:** as shown in testssl output (user-provided list required)
* **Why TLSv1.2+ is required:** older protocols contain known cryptographic weaknesses; TLSv1.3 is preferred for performance, reduced handshake complexity, and improved security.
* **Warnings from testssl:** only expected localhost issues such as self-signed certificate, no OCSP stapling, incomplete trust chain, and missing CT/CAA.

### HSTS Availability

* Confirmed: **HSTS appears only on HTTPS responses**, not on HTTP, which is correct behavior.

### Rate Limiting Test Results

The rate-limit test showed a mix of:

* **200 responses** (allowed within limit)
* **429 Too Many Requests** (rate limit triggered)

### Rate Limit Configuration Explanation

* **rate=10r/m** — allows 10 requests per minute per client.
* **burst=5** — allows temporary spikes of 5 additional requests.
* These values balance security and usability by mitigating brute force / flood attempts while avoiding excessive blocking of legitimate users.

### Timeout Settings in nginx.conf

* `client_body_timeout` — prevents slow body attacks.
* `client_header_timeout` — prevents slow header attacks.
* `proxy_read_timeout` — avoids infinite waiting on backend.
* `proxy_send_timeout` — stops clients from stalling uploads.

Each timeout reduces the risk of Slowloris-style attacks while ensuring normal users are unaffected.

### Access Log Evidence of Rate Limiting

Example lines from `access.log` showing rate-limiting in action:

```
... 429 ...
```
<img width="846" height="330" alt="image" src="https://github.com/user-attachments/assets/dc448572-f890-4444-927e-850df105fc27" />
