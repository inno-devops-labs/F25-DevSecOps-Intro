# Lab 11 — Reverse Proxy Hardening

## Task 1 — Reverse Proxy Compose Setup

### Security Benefits of Reverse Proxies

**Why reverse proxies are valuable for security:**

1. **TLS Termination** - Centralized SSL/TLS handling eliminates certificate management in each application
2. **Security Headers Injection** - Consistent security policies applied across all backend services  
3. **Request Filtering** - WAF capabilities, input validation, and malicious request blocking
4. **Single Access Point** - Unified entry point simplifies monitoring, logging, and access control

**Why hiding direct app ports reduces attack surface:**

- Applications are not directly exposed to the internet
- Only the hardened proxy is accessible from external networks
- Reduces number of exposed services and potential entry points
- Enables centralized security controls and monitoring

### Docker Compose Port Configuration Evidence

```bash
docker compose ps
```

```
NAME            IMAGE                           COMMAND                  SERVICE   CREATED          STATUS          PORTS
lab11-juice-1   bkimminich/juice-shop:v19.0.0   "/nodejs/bin/node /j…"   juice     15 seconds ago   Up 15 seconds   3000/tcp
lab11-nginx-1   nginx:stable-alpine             "/docker-entrypoint.…"   nginx     15 seconds ago   Up 14 seconds   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp, 80/tcp, 0.0.0.0:8443->8443/tcp, [::]:8443->8443/tcp
```

**Port Exposure Analysis:**
- **Nginx**: Exposes ports 8080 (HTTP) and 8443 (HTTPS) to host
- **Juice Shop**: No host ports exposed (only internal port 3000)
- **Configuration**: Only the reverse proxy is directly accessible


## Task 2 — Security Headers

### Security Headers Verification

**HTTPS Headers from `headers-https.txt`:**
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

### Security Headers Protection Analysis

**X-Frame-Options: DENY**
- **Protects against**: Clickjacking attacks
- **Prevents**: Page from being embedded in frames/iframes

**X-Content-Type-Options: nosniff**
- **Protects against**: MIME type sniffing attacks
- **Prevents**: Browser interpreting files as different content types

**Strict-Transport-Security: max-age=31536000; includeSubDomains; preload**
- **Protects against**: SSL stripping and protocol downgrade attacks
- **Enforces**: HTTPS-only connections for 1 year including subdomains

**Referrer-Policy: strict-origin-when-cross-origin**
- **Protects against**: Referrer information leakage
- **Controls**: How much referrer information is sent with requests

**Permissions-Policy: camera=(), geolocation=(), microphone=()**
- **Protects against**: Unauthorized access to device features
- **Restricts**: Camera, geolocation, and microphone APIs

**COOP/CORP: same-origin**
- **COOP protects against**: Cross-origin information leaks via window references
- **CORP protects against**: Cross-origin resource loading
- **Isolates**: browsing context to same-origin only

**CSP-Report-Only: default-src 'self'; img-src 'self' data:; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'**
- **Protects against**: XSS and content injection attacks
- **Monitors**: Policy violations without blocking (report-only mode)
- **Allows**: Safe development while testing CSP rules



## Task 3 — TLS, HSTS, Rate Limiting & Timeouts

###  TLS/SSL Security Analysis

**TLS Protocol Support:**
- [+] **TLS 1.3**: Offered (preferred)
- [+] **TLS 1.2**: Offered 
- [-] **TLS 1.1**: Not offered
- [-] **TLS 1.0**: Not offered
- [-] **SSLv3**: Not offered
- [-] **SSLv2**: Not offered

**Cipher Suites Supported:**
```
TLSv1.3:
- TLS_AES_256_GCM_SHA384
- TLS_CHACHA20_POLY1305_SHA256  
- TLS_AES_128_GCM_SHA256

TLSv1.2:
- ECDHE-RSA-AES256-GCM-SHA384
- ECDHE-RSA-AES128-GCM-SHA256
```

**TLS Version Requirements:**
- **TLSv1.3 required** for modern security (AEAD ciphers, improved handshake)
- **TLSv1.2+ mandatory** to avoid known vulnerabilities (POODLE, BEAST, etc.)
- **Older versions disabled** to prevent downgrade attacks

**Security Assessment:**
- [+] **Forward Secrecy**: Enabled (all ciphers support FS)
- [+] **Vulnerability Protection**: No Heartbleed, CCS, POODLE, BEAST, etc.
- [+] **Strong Encryption**: Only AEAD ciphers offered
- [-] **Certificate Trust**: Self-signed (expected for local development)
- [-] **OCSP Stapling**: Not offered (expected for self-signed cert)

**HSTS Verification:**
- [+] **HTTPS**: `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
- [+] **HTTP**: No HSTS header (correct behavior - only on HTTPS)

### Rate Limiting & Timeouts

**Rate Limit Test Results:**
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

**Rate Limit Analysis:**
- **First 6 requests**: 401 (authentication failed but allowed)
- **Next 6 requests**: 429 (rate limited - too many requests)
- **Success rate**: 6/12 requests allowed before limiting
- **Block rate**: 6/12 requests blocked by rate limiting

**Rate Limit Configuration:**
- **Rate**: 10 requests per minute (10r/m)
- **Burst**: 5 requests
- **Balance**: Allows legitimate user attempts while blocking brute-force attacks

**Timeout Settings Analysis:**
- **client_body_timeout**: Prevents slow client body upload attacks
- **client_header_timeout**: Prevents slowloris header attacks  
- **proxy_read_timeout**: Protects backend from slow responses
- **proxy_send_timeout**: Prevents backend connection exhaustion

**Security Trade-offs:**
- **Aggressive timeouts**: Better DoS protection but may affect slow connections
- **Conservative rate limits**: Balance security vs user experience
- **Burst allowance**: Prevents blocking legitimate users during normal activity

**Access Log Evidence:**
Rate limited requests would show 429 status codes in Nginx access logs, demonstrating effective brute-force protection for login endpoints.