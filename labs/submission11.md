## Task 1

#### Explain why reverse proxies are valuable for security (TLS termination, security headers injection, request filtering, single access point)

Reverse proxies introduces a various improvement to security.  
They use TLS termination, offloading encryption from backend servers to themselves.
They can inject security headers to enforce standarts like HSTS or CSP, centrally filtering requests, and providing modern encryption for legacy servers.
They validate all incoming requests before processing them.
THey function as a single point of access, hiding backend servers from user.

#### Explain why hiding direct app ports reduces attack surface

It prevents attackers from discovering and targeting those ports through scanning. This limits unauthorized access attempts and blocks common attack vectors associated with open listening ports

```
docker ps -a
CONTAINER ID   IMAGE                           COMMAND                  CREATED       STATUS       PORTS                                                                                              NAMES
8bc966580236   nginx:stable-alpine             "/docker-entrypoint.…"   3 hours ago   Up 3 hours   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp, 80/tcp, 0.0.0.0:8443->8443/tcp, [::]:8443->8443/tcp   lab11-nginx-1
b22c7917a132   bkimminich/juice-shop:v19.0.0   "/nodejs/bin/node /j…"   3 hours ago   Up 3 hours   3000/tcp                                                                                           lab11-juice-1```
```

## Task 2

```
HTTP/2 200 
server: nginx
date: Sat, 22 Nov 2025 11:47:49 GMT
content-type: text/html; charset=UTF-8
content-length: 75002
feature-policy: payment 'self'
x-recruiting: /#/jobs
accept-ranges: bytes
cache-control: public, max-age=0
last-modified: Sat, 22 Nov 2025 11:35:10 GMT
etag: W/"124fa-19aab58bd47"
vary: Accept-Encoding
strict-transport-security: max-age=31536000; includeSubDomains; preload
x-frame-options: DENY
x-content-type-options: nosniff
referrer-policy: strict-origin-when-cross-origin
permissions-policy: camera=(), geolocation=(), microphone=()
cross-origin-opener-policy: same-origin
cross-origin-resource-policy: same-origin
content-security-policy-report-only: default-src 'self'; img-src 'self' data:; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'
```

- X-Frame-Options: Prevents clickjacking by blocking framing
- X-Content-Type-Options: Stops MIME sniffing attacks
- Strict-Transport-Security (HSTS): Enforces HTTPS-only connections
- Referrer-Policy: Controls information sent in referrer
- Permissions-Policy: Restricts browser feature access
- COOP/CORP: Prevents cross-origin data leaks
- CSP-Report-Only: Reports Content Security Policy violations without enforcing

## Task 3
TLS/testssl summary:
Supported versions: TLS 1.2, TLS 1.3,

TLSv1.2 (server order)
 - xc030   ECDHE-RSA-AES256-GCM-SHA384       ECDH 256   AESGCM      256      TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384              
 - xc02f   ECDHE-RSA-AES128-GCM-SHA256       ECDH 256   AESGCM      128      TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256              

TLSv1.3 (server order)
 - x1302   TLS_AES_256_GCM_SHA384            ECDH 253   AESGCM      256      TLS_AES_256_GCM_SHA384                             
 - x1303   TLS_CHACHA20_POLY1305_SHA256      ECDH 253   ChaCha20    256      TLS_CHACHA20_POLY1305_SHA256                       
 - x1301   TLS_AES_128_GCM_SHA256            ECDH 253   AESGCM      128      TLS_AES_128_GCM_SHA256                             
 
Why TLS 1.2+ is required
- TLS 1.3 has better security and performance. Disabled obsolete protocols, PFS (Perfect Forward Secrecy) and uses more modern algorithms.

Warnings: 
- Chain of trust (self signed) - okay, in curret case, as dev certificates used
- OCSP URI neither CRL nor OCSP URI provided

Some vulnerabilities were tested, but none were found:
- Heartbleed
- CCS
- Ticketbleed
- ROBOT
- Secure Client-Initiated Renegotiation
- CRIME, TLS (CVE-2012-4929)           
- BREACH (CVE-2013-3587)
- POODLE, SSL (CVE-2014-3566)
- TLS_FALLBACK_SCSV (RFC 7507)
- SWEET32 (CVE-2016-2183, CVE-2016-6329)
- FREAK (CVE-2015-0204)                
- DROWN (CVE-2016-0800, CVE-2016-0703)
- LOGJAM (CVE-2015-4000)
- BEAST (CVE-2011-3389)
- LUCKY13 (CVE-2013-0169)
- Winshock (CVE-2014-6321)
- RC4 (CVE-2013-2566, CVE-2015-2808)

Strict-Transport-Security appeared only in `headers-https`. - Correct behaviour.


##### Rate limiting & timeouts:
There's total of 6 401 responces, and 6 429

Rate limit configuration
- `rate=10r/m`: 10 requests per minute (1 request every 6 seconds on average). Secures from brute-force attacks.
- `burst=5`: Allow up to 5 "burst" requests above the limit. Those are different options as burst requests frequently needed, but they are not happen at constant rate

Timeout settings in nginx.config
- client_body_timeout - Timeout for reading body of request. 
- client_header_timeout - Timeout for reading head of request.
- proxy_read_timeout - Backend read timeout.
- proxy_send_timeout - Sending to backend timeout.

Access log output
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
