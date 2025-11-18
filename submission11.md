# Lab 11 — Reverse Proxy Hardening: Nginx Security Headers, TLS, and Rate Limiting

## 1. Reverse Proxy Compose Setup (Task 1)

### 1.1 Why a Reverse Proxy?

Placing OWASP Juice Shop behind Nginx gives a single, controlled entry point in front of the app. That lets us:

- **Terminate TLS at the proxy**  
  Nginx handles certificates, ciphers, and protocol configuration, so the app doesn’t need to know anything about HTTPS. Rotating certs or changing TLS policy becomes an ops concern instead of an app-code change.

- **Inject and normalize security headers**  
  Headers like `X-Frame-Options`, `X-Content-Type-Options`, HSTS, and CSP can be set centrally at the proxy for *all* routes, including errors and redirects, without touching Juice Shop’s code.

- **Filter, throttle, and log requests**  
  Nginx can apply IP-based rate limiting, timeouts, and access control rules (e.g., on `/rest/user/login`) while Juice Shop only sees “cleaned” traffic.

- **Reduce attack surface**  
  Only Nginx is exposed to the internet/host; the Juice Shop container listens on an internal Docker network. Attackers can’t directly hit the Node.js process or any stray debug ports.

### 1.2 Hiding Direct App Ports

In this setup:

- Nginx publishes **only** the HTTPS/HTTP ports (e.g. `8080` for HTTP → redirect, `8443` for HTTPS).
- The Juice Shop container is *not* bound to any host ports; it’s only reachable by Nginx on the internal Docker network.


**Why this reduces attack surface:**
If Juice Shop were exposed directly (e.g. `0.0.0.0:3000`), attackers could bypass all Nginx protections and talk straight to the app. Keeping Juice Shop internal means **every** request must pass through Nginx, where TLS, headers, rate limiting, and logging are enforced.

---

## 2. Security Headers (Task 2)

### 2.1 Header Verification

I captured the headers using:

```bash
curl -sI http://localhost:8080/ > labs/lab11/analysis/headers-http.txt
curl -skI https://localhost:8443/ > labs/lab11/analysis/headers-https.txt
```

**HTTP (redirect) response** — key headers from `headers-http.txt`:

```http
HTTP/1.1 308 Permanent Redirect
Location: https://localhost:8443/
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), geolocation=(), microphone=()
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: same-origin
Content-Security-Policy-Report-Only: default-src 'self'; img-src 'self' data:; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'
```

**HTTPS response** — key headers from `headers-https.txt`:

```http
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

Note that **HSTS appears only on HTTPS**, not on the HTTP redirect response, which is the recommended behavior.

### 2.2 Header Explanations

* **X-Frame-Options: DENY**
  Blocks the site from being embedded in `<iframe>`s at all. This prevents **clickjacking attacks**, where an attacker might overlay a transparent UI over a trusted site to trick users into clicking actions they can’t see.

* **X-Content-Type-Options: nosniff**
  Tells browsers *not* to MIME-sniff content types and to trust the declared `Content-Type` instead. This reduces the risk of **content-type confusion**, e.g. a user-uploaded file being treated as JavaScript and executed.

* **Strict-Transport-Security (HSTS)**
  `strict-transport-security: max-age=31536000; includeSubDomains; preload`
  Instructs browsers to only use HTTPS for this host (and subdomains) for 1 year. This protects against **SSL stripping and downgrade attacks**, where an attacker tries to force a user back to HTTP. Once HSTS is cached, the browser won’t even attempt an HTTP connection.

* **Referrer-Policy: strict-origin-when-cross-origin**

    * Full URL is sent as `Referer` on same-origin requests.
    * Only the scheme/host/port (origin) is sent to other origins.
      This balances **privacy** (not leaking full paths or query params to third-party sites) while still keeping enough info for analytics and debugging on same-origin requests.

* **Permissions-Policy: camera=(), geolocation=(), microphone=()**
  Explicitly denies access to high-risk browser features (camera, mic, geolocation) for all origins. This shrinks the **attack surface** if any part of the app (or a third-party script) tried to request those capabilities.

* **Cross-Origin-Opener-Policy (COOP): same-origin**
  Forces top-level documents from other origins opened via `window.open` to be isolated in a different browsing context group. This mitigates some forms of cross-window attacks and side-channel leaks (e.g., Spectre-style attacks) by ensuring the app runs in a more isolated environment.

* **Cross-Origin-Resource-Policy (CORP): same-origin**
  Limits which origins can load resources from this server. With `same-origin`, only the same origin can embed resources (e.g. images, scripts). This reduces data exfiltration vectors where an attacker might try to embed sensitive resources on their own site.

* **Content-Security-Policy-Report-Only**

  ```http
  Content-Security-Policy-Report-Only: default-src 'self'; img-src 'self' data:; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'
  ```

  CSP in **Report-Only** mode lets us see (in logs/report endpoints) what *would* be blocked without actually breaking Juice Shop’s very JS-heavy UI. It’s a safe way to iterate toward a stricter CSP by collecting violation reports and tuning the policy before enforcing it.

---

## 3. TLS, HSTS, Rate Limiting & Timeouts (Task 3)

### 3.1 TLS & HSTS (testssl.sh)

I ran `testssl.sh` against the HTTPS endpoint:

```bash
# On Docker Desktop-type env:
docker run --rm drwetter/testssl.sh:latest https://host.docker.internal:8443 \
  | tee labs/lab11/analysis/testssl.txt
```

#### Supported Protocols

From `testssl.txt`:

* **SSLv2:** not offered ✅
* **SSLv3:** not offered ✅
* **TLS 1.0 / 1.1:** not offered ✅
* **TLS 1.2:** **offered** ✅
* **TLS 1.3:** **offered** ✅

This matches modern best practice: only TLSv1.2 and TLSv1.3 are enabled, which avoids downgrade attacks and legacy protocol vulnerabilities (e.g. BEAST, POODLE).

#### Cipher Suites

The server offers only strong AEAD ciphers with forward secrecy:

* **TLS 1.2:**

    * `ECDHE-RSA-AES256-GCM-SHA384`
    * `ECDHE-RSA-AES128-GCM-SHA256`
* **TLS 1.3:**

    * `TLS_AES_256_GCM_SHA384`
    * `TLS_CHACHA20_POLY1305_SHA256`
    * `TLS_AES_128_GCM_SHA256`

No NULL, export, RC4, or 3DES ciphers are offered (all reported as “not offered (OK)”).

**Why TLSv1.2+ (prefer TLSv1.3):**

* Older protocols (SSLv3, TLS 1.0/1.1) are tied to known issues like POODLE, BEAST, and weak ciphers.
* TLS 1.2 with GCM ciphers and forward secrecy is still widely accepted baseline.
* TLS 1.3 simplifies the handshake, enforces modern ciphers, and improves performance and security by design.

#### HSTS & Certificate Notes

From the `testssl` header analysis section:

* **HSTS:**
  `Strict Transport Security: 365 days, includeSubDomains, preload` — confirms the HSTS header is correctly set on HTTPS responses.

* **Self-signed Dev Cert Warnings:**

    * Chain of trust: **NOT ok (self signed)**
    * Domain name mismatch for `host.docker.internal` vs. CN `localhost`
    * No OCSP/CRL/CAA/CT data, OCSP stapling not offered

These are expected for a local, self-signed lab certificate. In a real deployment you’d use a trusted CA (e.g. Let’s Encrypt) and optionally enable OCSP stapling.

#### Vulnerability Checks

The `testssl` scan shows not vulnerable for:

* Heartbleed, CCS, Ticketbleed, ROBOT, CRIME, BREACH, POODLE, FREAK, DROWN, LOGJAM, SWEET32, RC4 usage, etc.

So the TLS configuration is modern and sane for this lab.

---

### 3.2 Rate Limiting on Login

Rate limiting is applied on `/rest/user/login` using Nginx `limit_req` with a configured rate and burst, returning HTTP `429` when limits are exceeded.

I triggered the rate limit with:

```bash
for i in $(seq 1 12); do \
  curl -sk -o /dev/null -w "%{http_code}\n" \
  -H 'Content-Type: application/json' \
  -X POST https://localhost:8443/rest/user/login \
  -d '{"email":"a@a","password":"a"}'; \
done | tee labs/lab11/analysis/rate-limit-test.txt
```

**Observed status codes (`rate-limit-test.txt`):**

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

Interpretation:

* The **first 6 requests** hit the application and returned `401` (unauthorized) for invalid credentials.
* The **next 6 requests** were blocked by Nginx and returned **`429 Too Many Requests`** once the configured rate + burst threshold was exceeded.

This behavior is exactly what we want: attackers trying to brute-force login will quickly run into 429s, slowing them down and making large-scale guessing attacks expensive.

#### Access Log Evidence

From `access.log` for the login tests:

```text
192.168.65.1 - - [18/Nov/2025:19:29:32 +0000] "POST /rest/user/login HTTP/2.0" 401 26 "-" "curl/8.7.1"
...
192.168.65.1 - - [18/Nov/2025:19:29:32 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.7.1"
192.168.65.1 - - [18/Nov/2025:19:29:32 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.7.1"
...
```

We see a burst of `401` responses followed by multiple `429` responses from the same client IP and path, matching the test output.

#### Rate Limit Configuration (Conceptual)

The Nginx config uses something like:

```nginx
limit_req_zone $binary_remote_addr zone=login_zone:10m rate=10r/m;

location = /rest/user/login {
    limit_req zone=login_zone burst=5 nodelay;
    limit_req_status 429;
    ...
}
```

* **`rate=10r/m`** – baseline of 10 login attempts per minute per IP.

    * Reasonable for humans, but throttles bots.
* **`burst=5`** – allows short spikes (e.g. a user double-clicking or quick retries) without immediately blocking.
* **`nodelay`** – once the burst is exhausted, extra requests are rejected immediately with `429` instead of being queued.

**Trade-off:**
This setting is a middle ground: strict enough to hurt brute-force attempts, but lenient enough that normal users who occasionally mistype passwords don’t get blocked after 1–2 tries.

---

### 3.3 Timeouts & DoS Resilience

In the `nginx.conf` (conceptually), the following timeouts are used to reduce the impact of slowloris-style or hanging connections:

* **`client_header_timeout`**
  Maximum time allowed to receive the full request headers from the client. Protects against clients that open a connection and send headers *very* slowly to tie up worker processes.

* **`client_body_timeout`**
  Time allowed for the HTTP request body to arrive (for POST/PUT, including login). Prevents an attacker from sending the body extremely slowly to keep connections open and exhaust resources.

* **`proxy_read_timeout`**
  Maximum time Nginx will wait for a response from the upstream (Juice Shop). Stops hung/slow upstream calls from tying up the proxy indefinitely.

* **`proxy_send_timeout`**
  Maximum time Nginx gives the client to receive data. If the client reads too slowly, the connection is closed, which helps against some resource-exhaustion scenarios.

**Trade-offs:**

* **Security:** Tight timeouts reduce the window for slowloris/DoS style attacks and free resources more quickly when clients misbehave.
* **Usability:** Timeouts that are *too* short can hurt users on slow connections or during genuinely slow backend operations (e.g., large reports). So the chosen values need to be high enough for normal user behavior, low enough to mitigate abuse.

---

## 4. Overall Trade-offs & Summary

* **Reverse proxy as security choke point:**
  All traffic must pass through Nginx, where TLS, headers, logging, and rate limiting are enforced. This dramatically reduces direct exposure of the Juice Shop app and makes it easier to change security posture centrally.

* **Security headers vs. compatibility:**
  Headers like XFO, XCTO, Referrer-Policy, COOP/CORP, and Permissions-Policy are essentially “free” wins. HSTS and CSP require more care: HSTS locks you into HTTPS (great for production, but tricky during migrations), and CSP can break apps if made too strict too quickly. Using CSP in Report-Only mode is a good compromise for this lab.

* **TLS configuration vs. legacy clients:**
  Supporting only TLS 1.2 and 1.3 with modern AEAD ciphers is the right call for security, but very old clients (e.g., old Java or IE on old Windows) can’t connect. For internet-facing apps, that’s generally acceptable today; internal legacy environments might need transitional policies.

* **Rate limiting & timeouts vs. user experience:**
  Rate limiting (`401` then `429`) and sensible timeouts make brute-force and slowloris attacks harder. The trade-off is that extremely aggressive settings could occasionally frustrate legitimate users (e.g., frequent password typos or very slow connections). The chosen values and behavior here strike a reasonable lab balance.
