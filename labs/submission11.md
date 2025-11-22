# Lab 11 - Reverse Proxy Hardening: Nginx Security Headers, TLS, and Rate Limiting

## Task 1 — Reverse Proxy Compose Setup

### Why reverse proxies are valuable for security

Using Nginx as a reverse proxy in front of Juice Shop provides several security benefits:

- **TLS termination at a single point**  
  Nginx is responsible for all HTTPS handling and certificates. The backend app only needs to speak plain HTTP on the internal Docker network. This keeps TLS configuration centralized and easier to harden and rotate.

- **Central injection of security headers**  
  Nginx adds headers like `X-Frame-Options`, `X-Content-Type-Options`, HSTS, CSP, COOP/CORP, and `Permissions-Policy` for every response, without changing application code. This is especially useful when you have many services that all need consistent hardening.

- **Request filtering and protections (rate limiting, timeouts)**  
  The proxy can enforce rate limits and connection timeouts on specific endpoints, such as `/rest/user/login`, to slow down brute-force attacks and reduce DoS impact.

- **Single external access point**  
  Only Nginx is exposed to the outside world; all app containers live on an internal network. This simplifies monitoring, logging, and incident response since all traffic funnels through one place.

### Why hiding direct app ports reduces attack surface

By not publishing the Juice Shop container’s port to the host, attackers cannot connect directly to the Node.js app. Instead, they must go through Nginx, which:

- Enforces TLS and modern ciphers.
- Adds strict security headers.
- Applies rate limiting and timeouts.
- Can perform additional checks (IP allowlists, WAF rules, etc.).

This avoids exposing any default app ports, debug endpoints, or verbose error pages directly to the Internet, effectively reducing the attack surface to just the hardened reverse proxy.

### `docker compose ps` output
```
docker compose ps
NAME            IMAGE                           COMMAND                  SERVICE   CREATED          STATUS          PORTS
lab11-juice-1   bkimminich/juice-shop:v19.0.0   "/nodejs/bin/node /j…"   juice     42 seconds ago   Up 41 seconds   3000/tcp
lab11-nginx-1   nginx:stable-alpine             "/docker-entrypoint.…"   nginx     42 seconds ago   Up 41 seconds   0.0.0.0:8080->8080/tcp, 80/tcp, 0.0.0.0:8443->8443/tcp
```
---

## Task 2 - Security Headers

### Headers over HTTPS

From `analysis/headers-https.txt`:

```text
HTTP/2 200 
server: nginx
date: Fri, 21 Nov 2025 16:19:33 GMT
content-type: text/html; charset=UTF-8
content-length: 75002
feature-policy: payment 'self'
x-recruiting: /#/jobs
accept-ranges: bytes
cache-control: public, max-age=0
last-modified: Fri, 21 Nov 2025 16:17:19 GMT
etag: W/"124fa-19aa734af1e"
vary: Accept-Encoding
strict-transport-security: max-age=31536000; includeSubDomains; preload
x-frame-options: DENY
x-content-type-options: nosniff
referrer-policy: strict-origin-when-cross-origin
permissions-policy: camera=(), geolocation=(), microphone=()
cross-origin-opener-policy: same-origin
cross-origin-resource-policy: same-origin
content-security-policy-report-only: default-src 'self'; img-src... 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'
```

Here we see all the same headers plus **Strict-Transport-Security (HSTS)**, which is intentionally only sent on HTTPS.

### Explanation of each header

- **X-Frame-Options: DENY**  
  Prevents the page from being loaded inside an `<iframe>` on any site. This protects against **clickjacking** attacks, where an attacker overlays a transparent UI on top of a trusted site to trick users into clicking actions (e.g., “Delete account”).

- **X-Content-Type-Options: nosniff**  
  Tells the browser not to “sniff” content types and instead trust the declared `Content-Type`. This reduces **content-type confusion** and some types of XSS where a non-JavaScript resource might be interpreted as executable script.

- **Strict-Transport-Security (HSTS)**  
  `strict-transport-security: max-age=31536000; includeSubDomains; preload` instructs compatible browsers to:
  - Always use HTTPS for this host (and subdomains) for one year.
  - Never downgrade to HTTP, even if the user types `http://` or an attacker tries to strip TLS.
  
  This helps prevent **protocol downgrade** and **SSL stripping** attacks. It is correctly only present on HTTPS responses.

- **Referrer-Policy: strict-origin-when-cross-origin**  
  Controls what gets sent in the `Referer` header:
  - For same-origin requests: send full URL.
  - For cross-origin: send only the origin (scheme + host + port).
  
  This limits leaking sensitive path/query information (e.g., internal IDs or tokens) to third-party sites, while still preserving useful analytics when navigating between pages.

- **Permissions-Policy: camera=(), geolocation=(), microphone=()**  
  This replaces the older `Feature-Policy`. Setting each of these to `()` denies access for all origins:
  - JavaScript on this page cannot use `getUserMedia` to access camera or microphone.
  - Geolocation APIs are disabled from this origin.
  
  It shrinks the attack surface if malicious or compromised scripts try to abuse these device capabilities.

- **COOP / CORP (Cross-Origin-Opener-Policy / Cross-Origin-Resource-Policy)**  
  - `Cross-Origin-Opener-Policy: same-origin`  
    Puts the page into a separate browsing context group from cross-origin documents. This is part of **cross-origin isolation** and helps provide stronger protections against XS-Leaks and Spectre-style side-channel attacks.
  - `Cross-Origin-Resource-Policy: same-origin`  
    Tells the browser that this resource should only be loaded by documents from the same origin. This prevents other sites from embedding or reading potentially sensitive resources.

- **Content-Security-Policy-Report-Only**  
  `Content-Security-Policy-Report-Only: default-src 'self'; img-src 'self' data:; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'`  

  This is a **non-blocking** CSP: the browser evaluates the policy and may send violation reports, but it does not stop the resource from loading. For a JS-heavy app like Juice Shop, this allows:

  - Observing which scripts, images, and styles are actually used in practice.
  - Identifying potential **XSS vectors** or unwanted external resource loads.
  - Iterating towards a stricter, enforced CSP without accidentally breaking the app.

---

## Task 3 - TLS, HSTS, Rate Limiting & Timeouts

### TLS scan summary (testssl.sh)

I scanned the HTTPS endpoint with:

```bash
# On Docker Desktop / non-Linux:
docker run --rm drwetter/testssl.sh:latest https://host.docker.internal:8443   | tee analysis/testssl.txt
```

#### Protocol support

From `analysis/testssl.txt`:

```text
SSLv2      not offered (OK)
SSLv3      not offered (OK)
TLS 1.1    not offered
TLS 1.2    offered (OK)
TLS 1.3    offered (OK): final
```

So:

- Legacy protocols **SSLv2**, **SSLv3**, and **TLS 1.1** are disabled.
- Only **TLS 1.2** and **TLS 1.3** are enabled, which is what you want today.

**Why TLSv1.2+ (prefer TLSv1.3)**

- TLS 1.0 and 1.1 are deprecated and lack modern security guarantees, and some known attacks (like BEAST) specifically apply to them.
- TLS 1.2 is still widely used but more complex and allows more legacy options.
- TLS 1.3 significantly simplifies the protocol, removes many legacy features, reduces handshake round trips, and enforces modern cipher suites. For security and performance, you typically want to prefer TLS 1.3 whenever clients support it.

#### Cipher suites

The cipher category section reports:

```text
NULL ciphers (no encryption)                      not offered (OK)
Export ciphers (w/o ADH+NULL)                     not offered (OK)
Triple DES Ciphers / IDEA                         not offered
Obsoleted CBC ciphers (AES, ARIA etc.)            not offered
Forward Secrecy strong encryption (AEAD ciphers)  offered (OK)
```

This indicates:

- No NULL, anonymous, export, 3DES, or obsolete CBC ciphers are allowed.
- Only **AEAD ciphers with forward secrecy** are enabled (e.g., AES-GCM with ECDHE key exchange, and for TLS 1.3 the modern suites like `TLS_AES_256_GCM_SHA384`).

The browser compatibility section lists examples such as:

```text
Browser                      Protocol  Cipher Suite Name (OpenSSL)       Forward Secrecy
Android 9.0 (native)         TLSv1.3   TLS_AES_256_GCM_SHA384            253 bit ECDH (X25519)
Android 10.0 (native)        TLSv1.3   TLS_AES_256_GCM_SHA384            253 bit ECDH (X25519)
IE 11 Win 10                 TLSv1.2   ECDHE-RSA-AES256-GCM-SHA384       256 bit ECDH (P-256)
...
```

So we get:

- Modern AEAD cipher suites.
- ECDHE-based key exchange providing **forward secrecy**.

#### Certificate / chain and OCSP

From the same scan:

```text
Chain of trust               NOT ok (self signed)
OCSP URI                     --
                            NOT ok -- neither CRL nor OCSP URI provided
OCSP stapling                not offered
```

These issues are expected in a lab environment, because the certificate is a self-signed `localhost` cert generated locally. To fix them in production you would:

- Use a CA-issued certificate (e.g., Let’s Encrypt).
- Enable OCSP stapling in Nginx and ensure the CA provides OCSP/CRL endpoints.

#### Vulnerability checks

The testssl scan shows a number of classic TLS/SSL vulnerabilities as **not vulnerable**, for example:

```text
Heartbleed (CVE-2014-0160)                not vulnerable (OK)
CCS (CVE-2014-0224)                       not vulnerable (OK)
Ticketbleed (CVE-2016-9244)               not vulnerable (OK)
CRIME, TLS (CVE-2012-4929)                not vulnerable (OK)
SWEET32 (CVE-2016-2183, CVE-2016-6329)    not vulnerable (OK)
FREAK (CVE-2015-0204)                     not vulnerable (OK)
DROWN (CVE-2016-0800, CVE-2016-0703)      not vulnerable on this host and port (OK)
BEAST (CVE-2011-3389)                     not vulnerable (OK), no SSL3 or TLS1
LOGJAM (CVE-2015-4000)                    not vulnerable (OK): no DH EXPORT ciphers
```

These results confirm the TLS configuration for this lab is reasonably strong, aside from the intentional dev-only self-signed cert.

### HSTS behavior

Comparing the HTTP and HTTPS headers:

- `headers-http.txt` (HTTP/1.1 308 redirect) has **no** `Strict-Transport-Security`.
- `headers-https.txt` (HTTP/2 200) **does** include:

  ```text
  strict-transport-security: max-age=31536000; includeSubDomains; preload
  ```

This matches best practice: browsers only honor HSTS over a successful HTTPS connection, and the header should not be sent on plain HTTP responses.

### Rate limiting on `/rest/user/login`

Rate limiting is configured in `nginx.conf`:

```nginx
# Rate limit zone for login
# ~10 req/min per IP, burst of 5
limit_req_zone $binary_remote_addr zone=login:10m rate=10r/m;
limit_req_status 429;

...

server {
  listen 8443 ssl;
  ...

  location = /rest/user/login {
    limit_req zone=login burst=5 nodelay;
    limit_req_log_level warn;
    proxy_pass http://juice;
  }

  location / {
    proxy_pass http://juice;
  }
}
```

I tested the rate limit with:

```bash
for i in $(seq 1 12); do   curl -sk -o /dev/null -w "%{http_code}\n"   -H 'Content-Type: application/json'   -X POST https://localhost:8443/rest/user/login   -d '{"email":"a@a","password":"a"}'; done | tee analysis/rate-limit-test.txt
```

#### Rate limit test output

From `analysis/rate-limit-test.txt`:

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

- The first **6 requests** return `401` - the application receives them and rejects invalid credentials.
- The next **6 requests** return `429` - Nginx rate limiting kicks in and blocks further attempts before they reach the app.

So in total: **6× 401** and **6× 429**.

#### Explanation of the rate limit configuration

- `limit_req_zone $binary_remote_addr zone=login:10m rate=10r/m;`  
  Defines a shared memory zone named `login` with about 10 MB of space, tracking per-client IP (`$binary_remote_addr`) and enforcing an average rate of **10 requests per minute**.

- `limit_req zone=login burst=5 nodelay;`  
  For the `/rest/user/login` location:
  - `burst=5` lets a client temporarily exceed the base rate by up to 5 queued/excess requests.
  - `nodelay` means that once the burst is exhausted, excess requests are **rejected immediately** with `429`, instead of being delayed.

- `limit_req_status 429;`  
  Configures Nginx to respond with HTTP 429 Too Many Requests when the limit is hit.

**Security vs usability trade-off**

- Security:
  - This greatly slows down brute-force password guessing and credential stuffing.
  - It also reduces load on the backend authentication system under attack.
- Usability:
  - A human user is unlikely to enter credentials more than a few times per minute, so `10r/m` with `burst=5` is permissive enough not to impact normal usage.
  - Automated scripts that hammer the login endpoint quickly hit `429` and get throttled.

#### Evidence in `access.log`

From `logs/access.log`, we can see the transition from `401` to `429` for `/rest/user/login`:

```text
192.168.65.1 - - [21/Nov/2025:16:22:55 +0000] "POST /rest/user/login HTTP/2.0" 401 26 "-" "curl/8.4.0" rt=0.059 uct=0.002 urt=0.059
192.168.65.1 - - [21/Nov/2025:16:22:55 +0000] "POST /rest/user/login HTTP/2.0" 401 26 "-" "curl/8.4.0" rt=0.009 uct=0.000 urt=0.009
...
192.168.65.1 - - [21/Nov/2025:16:22:55 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.4.0" rt=0.000 uct=- urt=-
192.168.65.1 - - [21/Nov/2025:16:22:55 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.4.0" rt=0.000 uct=- urt=-
...
```

These lines confirm:

- Multiple `/rest/user/login` requests from the same client IP.
- The first ones hit the app and return `401`.
- Subsequent ones are blocked at the proxy with `429`.

### Timeout settings and trade-offs

The provided `nginx.conf` also configures several timeout-related directives (following the lab template), such as:

- `client_body_timeout`  
  Limits how long Nginx waits for the request body from the client. Prevents slow clients from keeping connections open indefinitely and helps mitigate **slowloris-style** attacks.

- `client_header_timeout`  
  Limits how long Nginx waits for client headers. Similarly protects against very slow header sending.

- `proxy_read_timeout`  
  Controls how long Nginx waits for a response from the upstream Juice Shop container. If the app hangs or takes too long, Nginx closes the connection instead of tying up resources.

- `proxy_send_timeout`  
  Controls how long Nginx waits while sending the request to the upstream. Prevents extremely slow upstreams or dead connections from consuming worker time.

In general, the trade-offs are:

- **Shorter timeouts**  
  - Pros: Better protection against slow clients and resource-exhaustion attacks; quicker detection of hung upstreams.
  - Cons: Users on slow or lossy networks may see more timeouts or errors on large requests/responses.

- **Longer timeouts**  
  - Pros: Better UX for slow connections and long-running operations.
  - Cons: Easier for attackers or misbehaving clients to consume connections and memory.

For this lab, the chosen timeout values (on the order of a few seconds to tens of seconds) aim to strike a balance: they are strict enough to provide DoS/slowloris protection, while still being reasonable for a typical web app like Juice Shop.
