# Task 1

### Explain why reverse proxies are valuable for security (TLS termination, security headers injection, request filtering, single access point)

Reverse proxies provide a critical security layer for web applications by managing common threats before they reach the application itself. A reverse proxy significantly enhances security by centralizing multiple defense mechanisms. It acts as a single, secured entry point, handling TLS termination to offload encryption from the application and consistently injecting critical security headers. By inspecting all incoming traffic, it filters malicious requests, enforces rate limiting to prevent DoS attacks, and validates protocol compliance. This setup drastically reduces the attack surface by hiding the application's direct ports, forcing all communication through this protective gateway and eliminating direct exploitation avenues.

### Explain why hiding direct app ports reduces attack surface

Hiding the application's direct ports dramatically reduces the attack surface for one fundamental reason: it removes direct access to the application and forces all communication through a secured, intermediary layer.



### `docker compose ps` output

NAME          | IMAGE                         | COMMAND                | SERVICE | CREATED            | STATUS            | PORTS
------------- | ----------------------------- | ---------------------- | ------- | ------------------ | ----------------- | ------
lab11-juice-1 | bkimminich/juice-shop:v19.0.0 | "/nodejs/bin/node /j…" | juice   | About a minute ago | Up About a minute | 3000/tcp
lab11-nginx-1 | nginx:stable-alpine           | "/docker-entrypoint.…" | nginx   | About a minute ago | Up About a minute | 0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp, 80/tcp, 0.0.0.0:8443->8443/tcp, [::]:8443->8443/tcp



# Task 2

- **X-Frame-Options**: PClickjacking (UI redressing attacks)
- **X-Content-Type-Options**: MIME sniffing attacks
- **Strict-Transport-Security (HSTS)**:  SSL stripping and protocol downgrade attacks
- **Referrer-Policy**: Referrer information leakage
- **Permissions-Policy**:  Unauthorized access to browser features (camera, mic, etc.)
- **COOP/CORP**: Cross-origin isolation attacks (Spectre, data theft)
- **CSP-Report-Only**: No direct protection (testing phase for CSP policies)

```
strict-transport-security: max-age=31536000; includeSubDomains; preload
x-frame-options: DENY
x-content-type-options: nosniff
referrer-policy: strict-origin-when-cross-origin
permissions-policy: camera=(), geolocation=(), microphone=()
cross-origin-opener-policy: same-origin
cross-origin-resource-policy: same-origin
content-security-policy-report-only: default-src 'self'; img-src 'self' data:; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'
```


# Task 3

## TLS/testssl summary:
### Summarize TLS protocol support from testssl scan (which versions are enabled)

- TLS versions: TLS 1.2 and TLS 1.3 are enabled (SSLv2/SSLv3/TLS 1.0/1.1 are disabled).
- Example cipher suites in use:
	- TLS 1.3: TLS_AES_256_GCM_SHA384, TLS_CHACHA20_POLY1305_SHA256, TLS_AES_128_GCM_SHA256
	- TLS 1.2: ECDHE-RSA-AES256-GCM-SHA384, ECDHE-RSA-AES128-GCM-SHA256
	- Forward Secrecy is provided (ECDHE), and the server prefers cipher order; weak ciphers (RC4/3DES/NULL/EXPORT) are not advertised.

### List cipher suites that are supported

- See the examples above (TLS 1.3 and TLS 1.2 AEAD/ECDHE suites). TLS 1.3 ciphers are preferred where available.

### Explain why TLSv1.2+ is required (prefer TLSv1.3)

- TLS 1.2+ removes legacy protocol vulnerabilities; TLS 1.3 further hardens negotiation, reduces handshake rounds, and improves privacy and performance.

### Note any warnings or vulnerabilities from testssl output

- Warnings: the site uses a self-signed certificate (chain NOT OK). OCSP/CRL were not provided and OCSP stapling is not enabled. CT/CAA checks are not present — expected in local development.

### Confirm HSTS header appears only on HTTPS responses (not HTTP)

- HSTS appears in `headers-https.txt` and is not present in `headers-http.txt` (HTTP redirect), so HSTS is correctly only served over HTTPS.


## Rate limiting & timeouts

```
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
There are six "401 Unauthorized" responses (invalid credentials) followed by six "429 Too Many Requests" responses, which indicates the proxy's rate limiter blocked additional attempts after repeated failures.

### Rate-limit configuration (why `rate=10r/m`, `burst=5`)

The proxy enforces a limit of 10 requests per minute per source IP with a burst allowance of 5. This configuration accepts normal user behavior (short bursts or quick retries) while preventing high-frequency automated attacks and making single-host DoS/brute-force attempts much harder.

### Timeout settings in `nginx.conf` and trade-offs

| Timeout                      | Benefit of a short value                                               | Drawback of a short value   |
| ---------------------------- | ---------------------------------------------------------------------- | --------------------------- |
| client_{header,body}_timeout | Releases resources held by slow clients quickly                       | May disconnect legitimately slow clients |
| proxy_send_timeout           | Frees connections if the backend won't accept data                    | May abort requests during transient backend overloads |
| proxy_read_timeout           | Frees connections when upstream doesn't respond                       | May break valid long-running requests |

### Example lines from `access.log` showing 429 responses

```
192.168.65.1 - - [12/Nov/2025:17:35:11 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.7.1" rt=0.000 uct=- urt=-
192.168.65.1 - - [12/Nov/2025:17:35:11 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.7.1" rt=0.000 uct=- urt=-
192.168.65.1 - - [12/Nov/2025:17:35:11 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.7.1" rt=0.000 uct=- urt=-
192.168.65.1 - - [12/Nov/2025:17:35:11 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.7.1" rt=0.000 uct=- urt=-
192.168.65.1 - - [12/Nov/2025:17:35:11 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.7.1" rt=0.000 uct=- urt=-
192.168.65.1 - - [12/Nov/2025:17:35:11 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.7.1" rt=0.000 uct=- urt=-

```