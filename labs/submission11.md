# Lab 11 — Reverse Proxy Hardening: Nginx Security Headers, TLS, and Rate Limiting

## Task 1 — Reverse Proxy Compose Setup

Running Juice Shop behind Nginx turns the proxy into the single choke point that every client has to traverse. That setup matters for security because:

- **TLS termination** — Nginx is purpose-built for managing certificates, ciphers, and protocol policies, so it cleanly handles HTTPS for the entire stack without expecting the application container to embed its own crypto stack.
- **Security headers injection** — The proxy can enforce modern defaults such as XFO, XCTO, HSTS, Referrer-Policy, Permissions-Policy, and COOP/CORP globally, even though Juice Shop itself does not emit them.
- **Request filtering and rate controls** — Nginx can enforce allow/deny lists, rate limits, timeouts, and other filters before a request ever reaches the Node.js process, shrinking the window for brute-force or layer 7 DoS attempts.
- **Single access point for observability** — By exposing only the reverse proxy, logs, metrics, and WAF-like rules can be centralized in one place, which keeps incident response and hardening consistent.

Additionally, the `docker compose` layout hides the Juice Shop container’s internal port (`3000/tcp`) from the host altogether. Exposing only the proxy ports (8080/8443) shrinks the attack surface because scanners cannot talk to the app directly, cannot bypass the headers or TLS rules you enforce, and cannot reach any admin/debug endpoints that the app might accidentally bind. If a vulnerability exists behind the proxy, an attacker now has to defeat the proxy first.

### Evidence

```bash
$ docker compose ps
NAME            IMAGE                           COMMAND                  SERVICE   CREATED          STATUS          PORTS
lab11-juice-1   bkimminich/juice-shop:v19.0.0   "/nodejs/bin/node /j…"   juice     2 minutes ago    Up 2 minutes    3000/tcp
lab11-nginx-1   nginx:stable-alpine             "/docker-entrypoint.…"   nginx     2 minutes ago    Up 2 minutes    0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp, 0.0.0.0:8443->8443/tcp, [::]:8443->8443/tcp
```

Only `lab11-nginx-1` advertises host bindings. The Juice Shop container is reachable exclusively through the reverse proxy, which confirms the intended hardening for Task 1.

## Task 2 — Security Headers

`curl -sI http://localhost:8080/` (saved to `analysis/headers-http.txt`) showed the expected `HTTP/1.1 308 Permanent Redirect` plus our defensive headers but intentionally omitted HSTS so that browsers can still follow the upgrade. Once redirected, `curl -skI https://localhost:8443/` (captured in `analysis/headers-https.txt`) confirmed that the TLS path adds HSTS while keeping every other header identical:

```bash
$ curl -skI https://localhost:8443/
HTTP/2 200
strict-transport-security: max-age=31536000; includeSubDomains; preload
x-frame-options: DENY
x-content-type-options: nosniff
referrer-policy: strict-origin-when-cross-origin
permissions-policy: camera=(), geolocation=(), microphone=()
cross-origin-opener-policy: same-origin
cross-origin-resource-policy: same-origin
content-security-policy-report-only: default-src 'self'; img-src 'self' data:; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'
```

Header rationale:

- **X-Frame-Options** denies all framing so the UI cannot be clickjacked inside a hostile iframe.
- **X-Content-Type-Options** instructs browsers not to MIME-sniff, preventing polyglot payloads from being interpreted as executable content.
- **Strict-Transport-Security (HSTS)** tells browsers to always prefer HTTPS for one year (including subdomains), which blocks SSL stripping/downgrade attacks once the first secure visit occurs.
- **Referrer-Policy (strict-origin-when-cross-origin)** leaks only the scheme/host on cross-origin navigations, keeping full paths and sensitive tokens out of third-party logs.
- **Permissions-Policy** disables access to camera, geolocation, and microphone APIs unless explicitly delegated, limiting social-engineering attacks that try to invoke those sensors via the browser.
- **COOP/CORP** isolate the browsing context so other origins cannot interact with the Juice Shop window or fetch its responses, mitigating XS-Leaks and Spectre-style data exfiltration.
- **CSP-Report-Only** documents which sources are expected for scripts, styles, and images and reports (without blocking) any violation, which helps tune a stricter CSP to catch XSS and asset injection attempts.

## Task 3 — TLS, HSTS, Rate Limiting & Timeouts

`docker run --rm drwetter/testssl.sh:latest https://host.docker.internal:8443 | tee analysis/testssl.txt`

The `testssl.sh` scan verified that only TLS 1.2 and TLS 1.3 are enabled, with HTTP/2 negotiated via ALPN. All cipher suites are forward-secret AEAD options (`TLS_AES_256_GCM_SHA384`, `TLS_CHACHA20_POLY1305_SHA256`, `TLS_AES_128_GCM_SHA256`, plus the ECDHE‑RSA AES‑GCM pair for TLS 1.2). Keeping TLSv1.0/1.1 off the table forces clients to use modern crypto; older protocols lack critical fixes (no AEAD, exploitable renegotiation, weak ciphers) and are routinely disabled by compliance standards, so terminating at TLSv1.2+ is now the minimum bar. The tool reported only the expected localhost warnings: the self-signed cert breaks the trust chain, there is no OCSP/CRL/CAA metadata, and the hostname technically mismatches when probed via `host.docker.internal`. All vulnerability checks (Heartbleed, ROBOT, FREAK, LOGJAM, etc.) returned “not vulnerable.” The HTTP header test inside `testssl.sh` reiterated that HSTS is pinned for 31536000 seconds on HTTPS, while the HTTP 308 redirect response captured earlier still omits HSTS, satisfying the “HTTPS-only” requirement.

`for i in $(seq 1 12); do curl -sk -o /dev/null -w "%{http_code}\n" -H 'Content-Type: application/json' -X POST https://localhost:8443/rest/user/login -d '{"email":"a@a","password":"a"}'; done | tee analysis/rate-limit-test.txt`

The login flood produced six `401` responses before the burst bucket tripped and six `429` codes afterward:

```text
401
401
401
401
401
401
429
429
429
429
429
429
```

This proves the `limit_req` setting in `reverse-proxy/nginx.conf` is throttling `/rest/user/login` and returns the correct HTTP 429 signal once the burst allowance is exhausted.
