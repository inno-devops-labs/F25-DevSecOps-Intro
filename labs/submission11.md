# Task 1 — Reverse Proxy Compose Setup

## Why reverse proxies are valuable for security

Reverse proxies centralize TLS termination, offloading cryptographic operations from backend applications. They automatically inject security headers (HSTS, CSP, X-Frame-Options) into responses without code changes. They also filter malicious traffic (DDoS, SQL injection) before it reaches the application and provide a single entry point for access control, monitoring, and logging.

## Why hiding direct app ports reduces attack surface

Concealing application ports prevents direct exploitation of application vulnerabilities. All requests must pass through the hardened proxy layer for validation. This reduces exposed ports on the host and hides the backend's version and technology stack from attackers.

## `docker compose ps` output showing only Nginx has published host ports

```bash
lab11-nginx-1   nginx:stable-alpine             "/docker-entrypoint.…"   nginx     41 minutes ago   Up 41 minutes   0.0.0.0:8080->8080/tcp, 80/tcp, 0.0.0.0:8443->8443/tcp
```

---

# Task 2 — Security Headers

## Relevant security headers from `headers-https.txt`

1. **X-Frame-Options: DENY**
    - Prevents page rendering in frames/iframes, mitigating clickjacking attacks.

2. **X-Content-Type-Options: nosniff**
    - Prevents MIME type sniffing, blocking script execution from files disguised as other content types.

3. **Strict-Transport-Security (HSTS)**
    - Enforces HTTPS for 1 year, applies to subdomains, and supports browser preloading.

4. **Referrer-Policy: strict-origin-when-cross-origin**
    - Sends full referrer for same-origin requests, only origin for cross-origin requests.

5. **Permissions-Policy: camera=(), geolocation=(), microphone=()**
    - Disables camera, geolocation, and microphone APIs for all origins.

6. **Cross-Origin-Opener-Policy: same-origin**
    - Isolates browsing contexts from other origins, preventing cross-origin window access.

7. **Cross-Origin-Resource-Policy: same-origin**
    - Restricts cross-origin resource access, preventing cross-site information disclosure.

8. **Content-Security-Policy-Report-Only: default-src 'self'; img-src 'self' data:; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'**
    - Restricts resource loading to same origin, allows inline scripts/styles, collects violation reports without blocking content.

---

# Task 3 — TLS, HSTS, Rate Limiting & Timeouts

## TLS/testssl summary

1. **TLS protocol support:**
    - SSLv2, SSLv3, TLS 1.0, TLS 1.1: not offered
    - TLS 1.2, TLS 1.3: offered

2. **Supported cipher suites:**
    - **TLS 1.2:** ECDHE-RSA-AES256-GCM-SHA384, ECDHE-RSA-AES128-GCM-SHA256
    - **TLS 1.3:** TLS_AES_256_GCM_SHA384, TLS_CHACHA20_POLY1305_SHA256, TLS_AES_128_GCM_SHA256

3. **Why TLSv1.2+ is required:**
    - TLSv1.0/1.1 have known vulnerabilities (POODLE, BEAST). TLSv1.3 provides better security and performance. Legacy protocols lack modern cryptographic algorithms.

4. **Warnings from testssl output:**
    - Heartbleed, CCS, Ticketbleed, POODLE, BEAST, CRIME, BREACH, DROWN, LOGJAM, and others.

5. **HSTS header confirmation:**
    - Present only on HTTPS: `strict-transport-security: max-age=31536000; includeSubDomains; preload`
    - Not present on HTTP (returns `HTTP/1.1 308 Permanent Redirect`).

## Rate limiting & timeouts

1. **Rate-limit test output:**
    - 200 responses: 6
    - 429 responses: 6

2. **Rate limit configuration:**
    - `rate=10r/m`: 10 requests per minute baseline
    - `burst=5`: allows 5 additional requests before throttling
    - Protects against brute-force attacks while allowing legitimate multiple login attempts.

3. **Timeout settings:**
    - Short timeouts protect against Slowloris/DDoS attacks but may disrupt slow legitimate connections. Balance between security and accessibility.

4. **Relevant lines from `access.log` showing 429 responses:**
    ```bash
    172.18.0.1 - - [21/Nov/2025:13:07:23 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.7.1" rt=0.000 uct=- urt=-
    172.18.0.1 - - [21/Nov/2025:13:07:23 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.7.1" rt=0.000 uct=- urt=-
    172.18.0.1 - - [21/Nov/2025:13:07:23 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.7.1" rt=0.000 uct=- urt=-
    172.18.0.1 - - [21/Nov/2025:13:07:23 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.7.1" rt=0.000 uct=- urt=-
    172.18.0.1 - - [21/Nov/2025:13:07:23 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.7.1" rt=0.000 uct=- urt=-
    172.18.0.1 - - [21/Nov/2025:13:07:23 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.7.1" rt=0.000 uct=- urt=-
    ```
