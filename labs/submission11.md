# Lab 11 Submission — Nginx Reverse Proxy Hardening (Rewritten Version, Without Commands)

## Task 1 — Reverse Proxy Compose Setup

### Why a Reverse Proxy Strengthens Security
Having Nginx in front of the Juice Shop container provides several operational and security advantages:

- **Centralized HTTPS enforcement**
  All TLS negotiations occur at Nginx, which simplifies certificate lifecycle management and ensures the application never has to handle cryptographic configuration itself.

- **Consistent security headers**
  Many web apps do not provide modern security headers. By injecting headers at the proxy, we guarantee protections such as HSTS, X-Frame-Options, COOP/CORP, and others without touching application code.

- **Traffic management and filtering**
  The proxy can reject malformed or overly large requests, throttle abusive clients, and enforce strict timeouts—all of which reduce the burden on the backend.

- **A single controlled access point**
  External traffic is funneled through one hardened interface, making monitoring, auditing, and log review far more manageable.

### Why Keeping the App Port Internal Is Safer
By preventing Juice Shop from binding to a host port:

- attackers cannot directly scan or fingerprint the application
- brute-force tools cannot hit the backend without going through Nginx
- any malicious request must pass through the proxy’s filters and logging
- the backend service becomes invisible during port scans

This minimizes potential attack paths and ensures all incoming requests pass through a layer with enforced security policies.

### Verification That Only Nginx Exposes Ports
The container overview confirms:

- Nginx is the only service exposing ports to the host (`8080` and `8443`)
- Juice Shop only listens on its internal container port (`3000/tcp`) with no host mapping

This verifies that the application is reachable exclusively through the reverse proxy.

---

## Task 2 — Security Header Assessment

### Security Headers Returned Over HTTPS
The HTTPS response includes several defensive headers:

- **Strict-Transport-Security** with a one-year max age, subdomain coverage, and preload directive
- **X-Frame-Options: DENY**
- **X-Content-Type-Options: nosniff**
- **Referrer-Policy: strict-origin-when-cross-origin**
- **Permissions-Policy** disabling camera, geolocation, and microphone
- **COOP and CORP** set to `same-origin`
- **CSP in Report-Only mode** with a permissive policy compatible with Juice Shop

These collectively protect against clickjacking, MIME-sniffing, downgrade attacks, cross-origin leaks, and other common issues.

### Explanation of Each Header

#### Strict-Transport-Security (HSTS)
Instructs browsers to always use HTTPS for future connections, preventing SSL-stripping. It appears only on HTTPS responses, as required.

#### X-Frame-Options: DENY
Prevents embedding the site in iframes, protecting against clickjacking.

#### X-Content-Type-Options: nosniff
Stops MIME-type sniffing, reducing the risk of unintended script execution.

#### Referrer-Policy
Limits information shared during cross-site navigation. Only the origin is included, protecting sensitive URL paths.

#### Permissions-Policy
Disables access to camera, microphone, and geolocation APIs regardless of what scripts attempt.

#### Cross-Origin-Opener-Policy
Places the site in an isolated browsing context to reduce cross-origin data leakage.

#### Cross-Origin-Resource-Policy
Restricts which origins may load resources from this server, preventing unwanted embedding.

#### Content-Security-Policy (Report-Only)
Allows monitoring CSP violations without breaking Juice Shop's heavy inline scripting.

### Headers on HTTP (Before Redirect)
The HTTP response issues a permanent redirect to HTTPS while including most security headers except HSTS. This is correct, as browsers ignore HSTS over plain HTTP.

---

## Task 3 — TLS, HSTS, Rate Limiting & Timeouts

### TLS Scan Review
A TLS scan of the proxy confirms:

- Support for TLS 1.2 and TLS 1.3
- Deprecated protocols (SSLv2/3, TLS 1.0/1.1) are disabled
- Only strong cipher suites are enabled (AES-GCM, ChaCha20-Poly1305)
- Forward secrecy is provided through ECDHE
- Modern elliptic curves such as X25519 and secp384r1 are supported

This meets recommended TLS hardening guidelines.

### Expected Certificate-Related Warnings
Because a self-signed certificate is used for localhost, warnings about trust chain, OCSP, and CRL are expected. In a production setting, these would be resolved with a publicly trusted CA and OCSP stapling.

### HSTS Behavior
HSTS appears only on HTTPS responses, confirming correct configuration. HTTP responses omit it and instead redirect clients.

### Rate Limiting Behavior
Repeated login attempts eventually return `429 Too Many Requests` after several initial `401 Unauthorized` responses. This demonstrates that the rate limiter activates once thresholds are exceeded.

### Evidence from Access Logs
The access logs show multiple `429` entries for the login endpoint, meaning Nginx is enforcing the rate limit as intended.

### Evaluation of Rate Limit Configuration
The configured limits allow:

- roughly 10 allowed login attempts per minute
- a burst of 5 extra attempts before throttling begins

This is a reasonable balance between stopping automated brute-force attacks and allowing normal users to retry passwords.

### Timeout Configuration
Key timeout values include:

- short client header/body timeouts to reduce slowloris-style attacks
- moderate proxy read/send timeouts to avoid hanging upstream connections

These values protect against connection exhaustion while still supporting normal application behavior.
