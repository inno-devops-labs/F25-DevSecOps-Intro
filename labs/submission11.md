# Lab 11 — Reverse Proxy Hardening: Nginx Security Headers, TLS, and Rate Limiting

## Task 1 — Reverse Proxy Compose Setup

### Why reverse proxies are valuable for security

- TLS Termination: The proxy handles SSL/TLS encryption, offloading cryptographic processing from the application server and ensuring all external traffic is encrypted.

- Security Headers Injection: Centralized location to add security headers (X-Frame-Options, HSTS, CSP, etc.) without modifying application code.

- Request Filtering: Can block malicious requests, SQL injection attempts, and other attacks before they reach the application.

- Single Access Point: Provides a controlled entry point where all security policies can be enforced consistently.

- Load Balancing & Caching: Improves performance and availability while hiding backend architecture.

### Why hiding direct app ports reduces attack surface

- Host ports are not reachable from the host network or external network directly — only the proxy can connect to them. This prevents attackers from bypassing proxy controls and reduces exposed attack vectors.

- It enforces defense-in-depth: even if the app has a vulnerability, the proxy can mitigate or detect exploitation attempts before they reach the app.

```
$ docker compose ps
NAME            IMAGE                           COMMAND                  SERVICE   CREATED          STATUS          PORTS
lab11-juice-1   bkimminich/juice-shop:v19.0.0   "/nodejs/bin/node /j…"   juice     47 seconds ago   Up 46 seconds   3000/tcp
lab11-nginx-1   nginx:stable-alpine             "/docker-entrypoint.…"   nginx     47 seconds ago   Up 46 seconds   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp, 80/tcp, 0.0.0.0:8443->8443/tcp, [::]:8443->8443/tcp

$ curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:8080/
HTTP 308
```

## Task 2 — Security Headers

### Relevant security headers

- feature-policy: payment 'self'
- cache-control: public, max-age=0
- etag: W/"124fa-19aa6aee2bf"
- strict-transport-security: max-age=31536000; includeSubDomains; preload
- x-frame-options: DENY
- x-content-type-options: nosniff
- referrer-policy: strict-origin-when-cross-origin
- permissions-policy: camera=(), geolocation=(), microphone=()
- cross-origin-opener-policy: same-origin
- cross-origin-resource-policy: same-origin
- content-security-policy-report-only: default-src 'self'; img-src 'self' data:; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'

### Header Protection
1. X-Frame-Options: DENY

Protects against: Clickjacking attacks

2. X-Content-Type-Options: nosniff

Protects against: MIME type sniffing attacks

3. Strict-Transport-Security (HSTS)

Protects against: SSL stripping and protocol downgrade attacks

4. Referrer-Policy: strict-origin-when-cross-origin

Protects against: Information leakage through referrer headers

5. Permissions-Policy: camera=(), geolocation=(), microphone=()

Protects against: Unauthorized access to sensitive device features

6. COOP/CORP: same-origin

Protects against: Cross-origin information leakage and Spectre-type attacks

7. CSP-Report-Only

Protects against: XSS, data injection, and other code injection attacks

## Task 3 — TLS, HSTS, Rate Limiting & Timeouts

### TLS/testssl summary

#### TLS protocol support 

- TLS 1      not offered
- TLS 1.1    not offered
- TLS 1.2    offered (OK)
- TLS 1.3    offered (OK): final

#### Cipher suites that are supported

1. TLSv1.2 (server order)
- xc030   ECDHE-RSA-AES256-GCM-SHA384       ECDH 256   AESGCM      256      TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384              
- xc02f   ECDHE-RSA-AES128-GCM-SHA256       ECDH 256   AESGCM      128     TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256              
2. TLSv1.3 (server order)
- x1302   TLS_AES_256_GCM_SHA384            ECDH 253   AESGCM      256      TLS_AES_256_GCM_SHA384                             
- x1303   TLS_CHACHA20_POLY1305_SHA256      ECDH 253   ChaCha20    256      TLS_CHACHA20_POLY1305_SHA256                       
- x1301   TLS_AES_128_GCM_SHA256            ECDH 253   AESGCM      128      TLS_AES_128_GCM_SHA256 

#### Why TLSv1.2+ is required

- Security Vulnerabilities: TLS 1.0/1.1 have known weaknesses including POODLE, BEAST, and CRIME attacks

- Weak Cryptography: Older versions support insecure cipher suites and cryptographic algorithms

- No Forward Secrecy: TLS 1.0/1.1 don't guarantee perfect forward secrecy by default

#### Warnings or vulnerabilities

- Chain of trust               NOT ok (self signed)
- OCSP URI                     --
                              NOT ok -- neither CRL nor OCSP URI provided
- DNS CAA RR (experimental)    not offered

#### HSTS

- HTTPS Response: Strict-Transport-Security: max-age=31536000; includeSubDomains; preload present
- HTTP Response: HSTS header not present in HTTP 308 redirect response

### Rate limiting & timeouts

#### Rate-limit test output

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

```
172.20.0.1 - - [21/Nov/2025:13:54:03 +0000] "POST /rest/user/login HTTP/2.0" 401 26 "-" "curl/8.5.0" rt=0.074 uct=0.001 urt=0.073
172.20.0.1 - - [21/Nov/2025:13:54:03 +0000] "POST /rest/user/login HTTP/2.0" 401 26 "-" "curl/8.5.0" rt=0.018 uct=0.001 urt=0.018
172.20.0.1 - - [21/Nov/2025:13:54:04 +0000] "POST /rest/user/login HTTP/2.0" 401 26 "-" "curl/8.5.0" rt=0.016 uct=0.001 urt=0.016
172.20.0.1 - - [21/Nov/2025:13:54:04 +0000] "POST /rest/user/login HTTP/2.0" 401 26 "-" "curl/8.5.0" rt=0.017 uct=0.000 urt=0.017
172.20.0.1 - - [21/Nov/2025:13:54:04 +0000] "POST /rest/user/login HTTP/2.0" 401 26 "-" "curl/8.5.0" rt=0.015 uct=0.001 urt=0.015
172.20.0.1 - - [21/Nov/2025:13:54:04 +0000] "POST /rest/user/login HTTP/2.0" 401 26 "-" "curl/8.5.0" rt=0.012 uct=0.000 urt=0.012
```
```
172.20.0.1 - - [21/Nov/2025:13:54:04 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.5.0" rt=0.000 uct=- urt=-
172.20.0.1 - - [21/Nov/2025:13:54:04 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.5.0" rt=0.000 uct=- urt=-
172.20.0.1 - - [21/Nov/2025:13:54:04 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.5.0" rt=0.000 uct=- urt=-
172.20.0.1 - - [21/Nov/2025:13:54:04 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.5.0" rt=0.000 uct=- urt=-
172.20.0.1 - - [21/Nov/2025:13:54:04 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.5.0" rt=0.000 uct=- urt=-
172.20.0.1 - - [21/Nov/2025:13:54:04 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.5.0" rt=0.000 uct=- urt=-
```

- 6 requests returned 401 → normal authentication failures
- 6 requests returned 429 → rate limit activated

#### Rate limit configuration:

- rate=10r/m

Allows 10 requests per minute per IP

Prevents brute-force attacks while still allowing normal traffic

- burst=5

Allows a temporary burst of 5 extra requests

Improves usability — users can click multiple times without being blocked immediately

Still protects against automation / bots

#### Timeout settings

1. client_body_timeout 10s;

Closes the connection if the client takes too long to send the request body. 10 seconds is enough for normal login/API requests, while still preventing resource exhaustion.

2. client_header_timeout 10s;

Prevents slow-header attacks, where an attacker sends headers extremely slowly to occupy connections. 10 seconds is a safe value that still allows slower clients to connect.

3. proxy_read_timeout 30s;

If the backend takes longer than 30 seconds to respond, the connection is closed. 30 seconds is a reasonable compromise for API-style workloads.

4. proxy_send_timeout 30s;

Prevents Nginx from waiting indefinitely if the backend becomes unresponsive. 30 seconds avoids long hangs while still supporting normal request forwarding