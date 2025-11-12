# Task 1 — Reverse Proxy Compose Setup

## Why reverse proxies are valuable for security

The reverse proxy handles SSL/TLS encryption, offloading the main application from resource-intensive encryption/decryption operations. The proxy can automatically add important security headers (HSTS, CSP, X-Frame Options, etc.) to all responses, has the ability to block malicious requests, DDoS attacks, SQL injections at the proxy level until reaching the main application, and simplifies access control, monitoring, and logging of all incoming traffic.

## Why hiding direct app ports reduces attack surface

The direct ports of the application are not visible from the outside, which eliminates the possibility of direct attacks on vulnerabilities in the application itself. All requests pass through a secure proxy layer with additional validation, reducing the number of open ports on the host, which reduces the overall attack surface and makes it possible to hide the real version and technology stack of the backend application.

## ```docker compose ps``` output showing only Nginx has published host ports

```bash
lab11-nginx-1   nginx:stable-alpine             "/docker-entrypoint.…"   nginx     41 minutes ago   Up 41 minutes   0.0.0.0:8080->8080/tcp, 80/tcp, 0.0.0.0:8443->8443/tcp
```

---

# Task 2 — Security Headers

## Relevant security headers from ```headers-https.txt```

1. X-Frame-Options: DENY
    - Prohibits the display of the page in frame, iframe, object, or embed, preventing attacks when the user clicks on invisible elements.

2. X-Content-Type-Options: nosniff
    - The browser will only follow the specified Content-Type and will not attempt to automatically detect the type of content, which prevents scripts from being executed from files disguised as other types.

3. Strict-Transport-Security (HSTS)
    - Forcibly uses HTTPS connection for 1 year, enables all subdomains and allows preloading to browsers

4. Referrer-Policy: strict-origin-when-cross-origin
    - Sends a full referrer for same-origin requests, but only origin (without path) for cross-origin requests, balancing security and functionality.

5. Permissions-Policy: camera=(), geolocation=(), microphone=()
    - Blocks access to the camera, geolocation, and microphone for all sources, preventing web page surveillance.

6. Cross-Origin-Opener-Policy: same-origin
    - Isolates the window/tab from other origin

7. Cross-Origin-Resource-Policy: same-origin
    - Prohibits cross-origin access to resources

8. Content-Security-Policy-Report-Only: default-src 'self'; img-src 'self' data:; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'
    - The content security policy in report-only mode, which allows downloading resources only from the same origin, allows images with URI data, allows inline scripts and eval, allows inline styles, and collects reports on violations without blocking content

---

# Task 3 — TLS, HSTS, Rate Limiting & Timeouts

## TLS/testssl summary

1. Summarize TLS protocol support from testssl scan:
    - SSLv2 not offered
    - SSLv3 not offered
    - TLS 1 not offered
    - TLS 1.1 not offered
    - TLS 1.2 offered
    - TLS 1.3 offered

2. List cipher suites that are supported:
    - TLS 1.2:
        - ECDHE-RSA-AES256-GCM-SHA384
        - ECDHE-RSA-AES128-GCM-SHA256

    - TLS 1.3:
        - TLS_AES_256_GCM_SHA384
        - TLS_CHACHA20_POLY1305_SHA256
        - TLS_AES_128_GCM_SHA256

3. Why TLSv1.2+ is required:
    - TLSv1.0 and TLSv1.1 have known vulnerabilities (POODLE, BEAST)
    - TLSv1.3 provides improved security and performance
    - Outdated protocols do not support modern cryptographic algorithms
    - Compliance with modern safety standards

4. Warnings or vulnerabilities from testssl output:
    - Heartbleed
    - CCS
    - Ticketbleed
    - POODLE
    - BEAST
    - CRIME
    - BREACH
    - DROWN
    - LOGJAM
    - etc.

5. Confirm HSTS header appears only on HTTPS responses (not HTTP):

    The HSTS header appears only on HTTPS responses: ```strict-transport-security: max-age=31536000; includeSubDomains; preload```.

    There is no HSTS on HTTP responses (```HTTP/1.1 308 Permanent Redirect```).

## Rate limiting & timeouts

1. Rate-limit test output:
    
    Response 200 (6) vs. Response 429 (6)

2. Rate limit configuration

    - ```rate=10r/m``` - 10 requests per minute is the base limit.
    - ```burst=5``` - allows up to 5 additional requests over the limit

    These conifigurations protect against brute-force login attacks, allow legitimate users multiple login attempts, and block automated attacks without violating the UX.

3. Timeout settings in ```nginx.conf```:

    - Short timeouts protect against Slowloris/DDoS attacks
    - Timeouts that are too short may break legitimate slow connections.
    - A balance between security and accessibility for slow internet users

4. Relevant lines from ```access.log``` showing 429 responses:

    ```bash
    172.18.0.1 - - [03/Nov/2025:21:07:23 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.7.1" rt=0.000 uct=- urt=-
    172.18.0.1 - - [03/Nov/2025:21:07:23 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.7.1" rt=0.000 uct=- urt=-
    172.18.0.1 - - [03/Nov/2025:21:07:23 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.7.1" rt=0.000 uct=- urt=-
    172.18.0.1 - - [03/Nov/2025:21:07:23 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.7.1" rt=0.000 uct=- urt=-
    172.18.0.1 - - [03/Nov/2025:21:07:23 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.7.1" rt=0.000 uct=- urt=-
    172.18.0.1 - - [03/Nov/2025:21:07:23 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.7.1" rt=0.000 uct=- urt=-
    ```