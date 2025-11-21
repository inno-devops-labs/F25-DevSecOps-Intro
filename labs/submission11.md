# Lab 11 Submission

## Task 1

### Why reverse proxies are valuable for security:

**1. TLS Termination:** The reverse proxy handles all TLS encryption/decryption, centralizing certificate management and reducing the complexity of securing individual application instances. This allows the backend application to focus on business logic while the proxy handles cryptographic operations.

**2. Security Headers Injection:** The proxy can inject security headers (HSTS, X-Frame-Options, CSP, etc.) without requiring application code changes. This provides a consistent security posture across all applications behind the proxy.

**3. Request Filtering:** The proxy can filter malicious requests, implement rate limiting, and block suspicious traffic before it reaches the application. This creates a protective barrier that can prevent various attacks including DDoS and brute force attempts.

**4. Single Access Point:** All external traffic flows through the proxy, creating a centralized point for monitoring, logging, and access control. This simplifies security policies and makes it easier to implement consistent security measures.

### Why hiding direct app ports reduces attack surface:

When application ports are not directly exposed to the host, attackers cannot bypass the reverse proxy's security controls. This prevents:
- Direct exploitation of application vulnerabilities
- Bypassing rate limiting and security headers
- Accessing debug endpoints or admin interfaces
- Protocol-level attacks against the application server

The application becomes accessible only through the hardened reverse proxy, which acts as a security gateway that can inspect, filter, and modify all traffic according to security policies.

### Docker Compose Port Exposure Verification:

```bash
NAME            IMAGE                           COMMAND                  SERVICE   CREATED              STATUS              PORTS
lab11-juice-1   bkimminich/juice-shop:v19.0.0   "/nodejs/bin/node /j…"   juice     About a minute ago   Up About a minute   3000/tcp
lab11-nginx-1   nginx:stable-alpine             "/docker-entrypoint.…"   nginx     About a minute ago   Up About a minute   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp, 80/tcp, 0.0.0.0:8443->8443/tcp, [::]:8443->8443/tcp

```

**Analysis:** The output shows that:
- **Nginx (reverse-proxy)** has published ports: `0.0.0.0:8080->80/tcp, 0.0.0.0:8443->443/tcp` - accessible from the host
- **Juice Shop** only shows `3000/tcp` (internal port) with no host binding - not directly accessible from outside the Docker network

This confirms that the application is properly hidden behind the reverse proxy, with only the proxy's ports exposed to potential attackers.

## Task 2

### Security Headers from HTTPS Response:

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

### Header Security Analysis:

**X-Frame-Options: DENY** - Prevents the page from being displayed in a frame, iframe, embed or object. This protects against clickjacking attacks where malicious sites could overlay transparent frames to trick users into clicking on hidden elements or buttons.

**X-Content-Type-Options: nosniff** - Prevents browsers from MIME-sniffing a response away from the declared content-type. This stops browsers from interpreting files as a different MIME type than what the server declares, preventing attacks where malicious content is disguised as innocent file types.

**Strict-Transport-Security (HSTS): max-age=31536000; includeSubDomains; preload** - Forces browsers to use HTTPS for all connections to this domain for one year (31536000 seconds), including all subdomains. The `preload` directive enables inclusion in browser HSTS preload lists. This prevents downgrade attacks and man-in-the-middle attacks that try to force HTTP connections.

**Referrer-Policy: strict-origin-when-cross-origin** - Controls how much referrer information is sent with requests. When navigating to a different origin, only the origin (not the full URL) is sent as referrer. This protects user privacy and prevents sensitive information in URLs from leaking to external sites.

**Permissions-Policy: camera=(), geolocation=(), microphone=()** - Disables access to sensitive browser APIs like camera, geolocation, and microphone for all origins. This prevents malicious scripts from accessing these privacy-sensitive features without explicit user permission.

**COOP/CORP (Cross-Origin-Opener-Policy/Cross-Origin-Resource-Policy): same-origin** - COOP prevents other origins from gaining references to the window object, protecting against cross-origin attacks. CORP restricts which origins can embed or load this resource, preventing unauthorized cross-origin inclusion attacks and data theft.

**CSP-Report-Only: default-src 'self'; img-src 'self' data:; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'** - Content Security Policy in report-only mode monitors but doesn't block policy violations. This CSP restricts resource loading to same-origin sources with some exceptions for inline scripts/styles. While not enforcing yet, it helps identify potential XSS vectors and prepares for eventual enforcement without breaking application functionality.

## Task 3

### Testssl Summary:

**TLS Protocol Support:**
- SSLv2: Not offered (OK)
- SSLv3: Not offered (OK)
- TLS 1.0: Not offered
- TLS 1.1: Not offered
- TLS 1.2: Offered (OK)
- TLS 1.3: Offered (OK)

**Supported Cipher Suites:**

*TLS 1.2:*
- ECDHE-RSA-AES256-GCM-SHA384 (256-bit ECDH)
- ECDHE-RSA-AES128-GCM-SHA256 (256-bit ECDH)

*TLS 1.3:*
- TLS_AES_256_GCM_SHA384 (253-bit ECDH)
- TLS_CHACHA20_POLY1305_SHA256 (253-bit ECDH)
- TLS_AES_128_GCM_SHA256 (253-bit ECDH)

**Why TLS 1.2+ is Required (Prefer TLS 1.3):**
TLS 1.2+ is required because older versions (TLS 1.0/1.1, SSL) have known vulnerabilities and weak cryptographic algorithms. TLS 1.3 is preferred because it:
- Removes deprecated algorithms and cipher suites
- Provides improved forward secrecy
- Reduces handshake latency
- Eliminates known attack vectors present in earlier versions
- Supports only AEAD (Authenticated Encryption with Associated Data) ciphers

**Warnings and Vulnerabilities from testssl:**
- **Chain of trust:** NOT ok (self-signed) - Expected for development certificates
- **OCSP:** NOT ok - Neither CRL nor OCSP URI provided - Expected for self-signed certs
- **BREACH:** Potentially NOT ok due to gzip compression - Can be ignored for static pages
- **Overall Grade:** T (capped due to self-signed certificate)

All other vulnerability tests passed (Heartbleed, ROBOT, CRIME, POODLE, FREAK, DROWN, etc.)

**HSTS Header Verification:**
- **HTTP response (port 8080):** No HSTS header present (correct behavior)
- **HTTPS response (port 8443):** HSTS header present: `strict-transport-security: max-age=31536000; includeSubDomains; preload`

This confirms HSTS is correctly configured to appear only on HTTPS responses, preventing protocol downgrade attacks.

### Rate Limiting & Timeouts:

**Rate Limit Test Output:**
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

**Analysis:** 6 requests returned HTTP 401 (authentication failed), followed by 6 requests returning HTTP 429 (rate limited). This shows the rate limiting is working as expected.

**Rate Limit Configuration Analysis:**
- `rate=10r/m` (10 requests per minute)
- `burst=5` (allows up to 5 requests above the rate limit)

These values balance security vs usability by:
- **Security:** Preventing brute force attacks by limiting login attempts to a reasonable rate
- **Usability:** Allowing legitimate users some burst capacity for normal usage patterns
- **Recovery:** 1-minute window allows users to retry after brief lockout

**Timeout Settings in nginx.conf:**

- `client_body_timeout 30s`: Maximum time to read client request body
- `client_header_timeout 30s`: Maximum time to read client request headers  
- `proxy_read_timeout 60s`: Maximum time to receive response from upstream server
- `proxy_send_timeout 60s`: Maximum time to transmit request to upstream server

**Trade-offs:**
- **Security Benefits:** Prevents slowloris attacks and resource exhaustion from slow clients
- **Usability Considerations:** Values set high enough to accommodate legitimate slow connections and large uploads
- **Resource Protection:** Ensures proxy doesn't hold connections indefinitely

**Access Log 429 Responses:**
```
172.18.0.1 - - [21/Nov/2025:20:49:04 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.5.0" rt=0.000 uct=- urt=-
172.18.0.1 - - [21/Nov/2025:20:49:04 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.5.0" rt=0.000 uct=- urt=-
172.18.0.1 - - [21/Nov/2025:20:49:04 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.5.0" rt=0.000 uct=- urt=-
172.18.0.1 - - [21/Nov/2025:20:49:04 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.5.0" rt=0.000 uct=- urt=-
172.18.0.1 - - [21/Nov/2025:20:49:04 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.5.0" rt=0.000 uct=- urt=-
172.18.0.1 - - [21/Nov/2025:20:49:04 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.5.0" rt=0.000 uct=- urt=-
```

The logs show rate limiting is actively blocking excessive requests with immediate response times (`rt=0.000`), demonstrating effective protection against brute force attacks.

