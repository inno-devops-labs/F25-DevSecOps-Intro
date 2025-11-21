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

