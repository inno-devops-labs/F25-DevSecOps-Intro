# Lab 11 — Reverse Proxy Hardening: Nginx Security Headers, TLS, and Rate Limiting

---

## Task 1 — Reverse Proxy Compose Setup

### Reverse Proxy Security Benefits

- **TLS Termination**: Handles SSL encryption, offloading from apps
- **Security Headers**: Automatically adds security headers (CSP, HSTS, etc.)
- **Request Filtering**: Blocks malicious requests before reaching applications
- **Single Access Point**: Centralizes security monitoring and hides internal structure

#### Why Hiding App Ports Reduces Attack Surface

- Prevents direct attacks on application vulnerabilities
- Forces all traffic through security controls
- Hides internal network topology
- Adds defense in depth layer

#### Docker Compose PS Output

```
NAME                             IMAGE                    SERVICE        PORTS
lab11-juice-1                    bkimminich/juice-shop   juice          3000/tcp
lab11-reverse-proxy-1            nginx:alpine            reverse-proxy  0.0.0.0:8080->80/tcp
```

Only Nginx has published host ports. Juice Shop has no direct exposure.

---

## Task 2 — Security Headers

#### Headers Collected via HTTPS

The following security headers were collected from the HTTPS endpoint (`https://localhost:8443`) using `curl -skI`:

```http
HTTP/2 200
server: nginx
strict-transport-security: max-age=31536000; includeSubDomains; preload
x-frame-options: DENY
x-content-type-options: nosniff
referrer-policy: strict-origin-when-cross-origin
permissions-policy: camera=(), geolocation=(), microphone=()
cross-origin-opener-policy: same-origin
cross-origin-resource-policy: same-origin
content-security-policy-report-only: default-src 'self'; img-src 'self' data:; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'
```

#### Header Explanations and Protective Value

|Header|Protection|
|---|---|
|`Strict-Transport-Security`|Forces browsers to use HTTPS for one year, including subdomains, preventing protocol downgrade and SSL stripping attacks.|
|`X-Frame-Options: DENY`|Mitigates clickjacking by preventing the site from being rendered within a frame or iframe.|
|`X-Content-Type-Options: nosniff`|Prevents browsers from MIME-sniffing a response away from the declared Content-Type, blocking the execution of scripts disguised as other content types.|
|`Referrer-Policy`|Limits referrer information sent on cross-origin requests to the origin only (scheme, host, port), reducing leakage of sensitive path or query string data.|
|`Permissions-Policy`|Restricts access to powerful browser APIs (camera, geolocation, microphone), providing defense-in-depth against privacy leaks.|
|`Cross-Origin-Opener-Policy`|Isolates the browsing context from cross-origin windows, mitigating cross-origin side-channel attacks.|
|`Cross-Origin-Resource-Policy`|Instructs the browser to block cross-origin requests for resources, preventing other sites from directly embedding them.|
|`Content-Security-Policy-Report-Only`|Monitors but does not enforce a policy. It is a safe way to detect potential issues from inline scripts/styles before enforcing a blocking policy, which is crucial for complex applications like Juice Shop.|

---

## Task 3 — TLS, HSTS, Rate Limiting & Timeouts

#### TLS Configuration Summary

Analysis confirms effective TLS settings supporting only **TLS 1.2 and 1.3** with modern ciphers (`TLS_AES_256_GCM_SHA384`, `ECDHE-RSA-AES256-GCM-SHA384`). Forward secrecy is enabled via ECDHE.

- **Why TLS 1.2+?** Prevents known vulnerabilities in older protocols (POODLE, BEAST) and ensures strong encryption.
- **Expected Lab Warnings:** Self-signed certificate (normal for testing) and disabled OCSP stapling (should be enabled for production).

#### HSTS Placement

The `Strict-Transport-Security` header is correctly implemented—present on HTTPS responses but absent from HTTP redirects, as required.

#### Rate Limiting Test

Testing the `/rest/user/login` endpoint with rapid requests showed:

- 6× `401 Unauthorized` (failed logins)
- 6× `429 Too Many Requests` (rate limit active)

#### Configurations & Trade-offs:

```nginx
limit_req_zone $binary_remote_addr zone=login:10m rate=10r/m;
location = /rest/user/login {
  limit_req zone=login burst=5 nodelay;
}
```

- **Security:** 10 requests/minute per IP slows brute-force attacks
- **Usability:** `burst=5` allows legitimate retries; `nodelay` gives immediate feedback

#### Timeout Settings

- `client_header/body_timeout 10s` - Protects against Slowloris attacks but may affect slow legitimate connections
- `proxy_read/send_timeout 30s` - Prevents hung connections to backend; suitable for most web operations
