# Lab 11 — Reverse Proxy Hardening (Nginx TLS, Security Headers, and Rate Limiting)

## Task 1 — Reverse Proxy Compose Setup (2 pts)

### Why Reverse Proxies Matter

1. TLS termination — the proxy manages HTTPS; application containers do not hold private keys, reducing exposure.  
2. Security headers injection — nginx can add headers (HSTS, X-Frame-Options, etc.) centrally even if the app does not.  
3. Request filtering — rate limits and timeouts block abusive traffic before it reaches the application.  
4. Single access point — simplifies logging, monitoring and policy enforcement.  
5. Reduced attack surface — backend ports are not published to the host, preventing direct access.

### Verification

Commands used:

```bash
cd labs/lab11
docker compose up -d
docker compose ps
```

Observed `docker compose ps` output:

```
NAME            IMAGE                           SERVICE   STATUS          PORTS
lab11-juice-1   bkimminich/juice-shop:v19.0.0   juice     Up  (3000/tcp)
lab11-nginx-1   nginx:stable-alpine             nginx     Up  (0.0.0.0:8080->8080/tcp, 0.0.0.0:8443->8443/tcp)
```

Only Nginx exposes host ports (8080 / 8443). Juice Shop listens on the Docker network (`3000/tcp`) and is not directly reachable from the host — confirming the proxy is the single external access point.

---

## Task 2 — Security Headers Validation (3 pts)

### Captured HTTPS headers

Headers were collected with:

```bash
curl -skI https://localhost:8443/ | tee labs/lab11/analysis/headers-https.txt
```

Relevant HTTPS response headers (excerpt):

```
HTTP/2 200
server: nginx
date: Fri, 14 Nov 2025 13:57:40 GMT
content-type: text/html; charset=UTF-8
content-length: 75002
strict-transport-security: max-age=31536000; includeSubDomains; preload
x-frame-options: DENY
x-content-type-options: nosniff
referrer-policy: strict-origin-when-cross-origin
permissions-policy: camera=(), geolocation=(), microphone=()
cross-origin-opener-policy: same-origin
cross-origin-resource-policy: same-origin
content-security-policy-report-only: default-src 'self'; img-src 'self' data:; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'
```

### Header explanations (what each protects against)

| Header | Protection |
|--------|------------|
| X-Frame-Options: DENY | Prevents clickjacking by disallowing framing of the site. |
| X-Content-Type-Options: nosniff | Stops browsers from MIME‑sniffing and executing content as a different type. |
| Strict-Transport-Security (HSTS) | Forces browsers to use HTTPS for the domain (prevents protocol downgrade). Appears only on HTTPS responses. |
| Referrer-Policy: strict-origin-when-cross-origin | Limits referrer data sent on cross-origin requests, reducing leakage of sensitive URLs/tokens. |
| Permissions-Policy | Restricts access to powerful APIs (camera, mic, geolocation) to prevent privacy leaks. |
| COOP / CORP | Improves isolation between browsing contexts and resources to mitigate cross-origin data leaks. |
| Content-Security-Policy-Report-Only | Detects (but does not block) violations; useful to tune CSP before enforcement to reduce breakage. |

All expected hardening headers are present on the HTTPS response. The HTTP endpoint returns a redirect and does not include HSTS, which is the correct behaviour.

---

## Task 3 — TLS, HSTS, Rate Limiting & Timeouts (5 pts)

### 3.1 TLS / testssl-style summary

Quick live checks were performed using `openssl s_client` and header inspection. The results match the TLS settings in `nginx.conf`.

- Protocols confirmed: TLS 1.3 and TLS 1.2 are supported (handshake observed). TLS 1.0/1.1, SSLv2/3 are not used.  
- Example negotiated ciphers observed:
  - TLS_AES_256_GCM_SHA384 (TLS 1.3)
  - ECDHE-RSA-AES256-GCM-SHA384 (TLS 1.2)
- Cipher suites referenced in `nginx.conf` include modern AEAD ciphers and ECDHE/DHE options (see file for exact string).

Why TLSv1.2+ (prefer TLSv1.3): TLSv1.0/1.1 are deprecated and have known weaknesses. TLSv1.2 and TLSv1.3 support stronger ciphers and forward secrecy; TLSv1.3 additionally improves security and performance.

Notes / expected warnings on localhost with self-signed certs:

- The certificate is self-signed (openssl shows verify error: self-signed certificate). This will be reported as a chain-of-trust issue by formal scanners — acceptable for local testing.  
- OCSP stapling is disabled (`ssl_stapling off` in the config). For production, enable stapling and configure `resolver` and `ssl_trusted_certificate`.

Sample handshake excerpt:

```
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
New, TLSv1.2, Cipher is ECDHE-RSA-AES256-GCM-SHA384
Verification error: self-signed certificate
```

### 3.2 HSTS placement

- HTTP (port 8080) returns `308 Permanent Redirect` and does NOT include `Strict-Transport-Security`.  
- HTTPS (port 8443) includes `strict-transport-security: max-age=31536000; includeSubDomains; preload`.

HSTS is correctly applied only on HTTPS responses.

### 3.3 Rate limiting test

Test performed: 30 rapid POST requests to `/rest/user/login` (curl with `-k`). Observed status codes:

```
6 x 401  # application responses (invalid credentials)
24 x 429 # requests rejected by nginx limit_req
```

Access log excerpts showing 429 responses (samples):

```
172.18.0.1 - - [14/Nov/2025:13:57:10 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.5.0" rt=0.000 uct=- urt=-
172.18.0.1 - - [14/Nov/2025:13:57:11 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.5.0" rt=0.000 uct=- urt=-
```

Rate limiter configuration (from `nginx.conf`):

```nginx
limit_req_zone $binary_remote_addr zone=login:10m rate=10r/m;
location = /rest/user/login {
  limit_req zone=login burst=5 nodelay;
  limit_req_status 429;
  proxy_pass http://juice;
}
```

Explanation:

- `rate=10r/m` limits each IP to ~10 requests per minute — a conservative per-IP limit for login endpoints to slow brute-force attempts.  
- `burst=5` allows small retry bursts (useful for legitimate users) before limits apply.  
- `nodelay` returns 429 immediately for excess requests (no queuing), giving faster failure feedback and avoiding connection backlog.

### 3.4 Timeouts and trade-offs

Configured values in `nginx.conf`:

```
client_max_body_size 2m;
client_body_timeout 10s;
client_header_timeout 10s;
proxy_read_timeout 30s;
proxy_send_timeout 30s;
```

Trade-offs:

- Short client timeouts free resources and mitigate slow-client DoS (Slowloris) but can disrupt legitimately slow clients.  
- Proxy timeouts protect the proxy from hanging backends; increase if upstream operations are long-running.  
- `client_max_body_size` prevents large uploads from exhausting resources.

### Note on development certificates

On localhost a self-signed certificate will flag chain-of-trust and OCSP/stapling issues in automated scans. To eliminate those findings:

- Trust a local CA (e.g., mkcert) so browsers accept the cert, or
- Use a real domain and a public CA (e.g., Let's Encrypt) and enable OCSP stapling (`ssl_stapling on`) with a configured resolver.

---

## Files and evidence

- `labs/lab11/reverse-proxy/certs/localhost.crt` — self-signed certificate used for testing
- `labs/lab11/reverse-proxy/certs/localhost.key` — private key
- `labs/lab11/analysis/headers-https.txt` — captured HTTPS headers
- `labs/lab11/logs/access.log` — access log entries (contains 429 responses)
- `labs/lab11/logs/nginx.log` — nginx startup and messages
- `labs/lab11/logs/juice.log` — Juice Shop application log

---

## Acceptance checklist

- [x] Task 1 — Reverse proxy compose setup and verification
- [x] Task 2 — Security headers verification (HSTS present only on HTTPS)
- [x] Task 3 — TLS scan summary, HSTS confirmation, rate-limiting test and timeouts discussion

---

## Cleanup (optional)

```bash
cd labs/lab11
docker compose down
# rm -rf labs/lab11/reverse-proxy/certs/*  # optional: remove generated certs
```

---
