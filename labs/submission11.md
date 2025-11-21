## Task 1

#### Explain why reverse proxies are valuable for security (TLS termination, security headers injection, request filtering, single access point)


TLS termination - single point of updating TLS/SSL configuration.

Security headers injection - equal security for all services, legacy systems are protected

Request filtering - validation of requests before reaching backend

Single access point - Single point to access specified backend services.

#### Explain why hiding direct app ports reduces attack surface

Because it hides the project's architecture from attackers and makes it possible to clearly indicate what the user has access to.

```
NAME            IMAGE                           COMMAND                  SERVICE   CREATED          STATUS          PORTS
lab11-juice-1   bkimminich/juice-shop:v19.0.0   "/nodejs/bin/node /j…"   juice     22 seconds ago   Up 22 seconds   3000/tcp
lab11-nginx-1   nginx:stable-alpine             "/docker-entrypoint.…"   nginx     22 seconds ago   Up 22 seconds   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp, 80/tcp, 0.0.0.0:8443->8443/tcp, [::]:8443->8443/tcp
```


## Task 2

* X-Frame-Options: Allow show this website inside frames on other websites. `<iframe>`
* X-Content-Type-Options: Do not allow browser "guess" type of content. `nosniff` says that browser should strict use provided `Content-Type`
* Strict-Transport-Security (HSTS): Says browser that it have to use HTTPS connection
* Referrer-Policy: Controls that info transfers in Referer header
* Permissions-Policy: Can disable some functions for browser such as camera, microphone and etc.
* COOP/CORP: Isolate window of web page from other. All files can be loaded only from specified url.
* CSP-Report-Only: Test mode for CSP without blocking

```
HTTP/2 200 
server: nginx
date: Thu, 20 Nov 2025 20:17:55 GMT
content-type: text/html; charset=UTF-8
content-length: 75002
feature-policy: payment 'self'
x-recruiting: /#/jobs
accept-ranges: bytes
cache-control: public, max-age=0
last-modified: Thu, 20 Nov 2025 18:28:49 GMT
etag: W/"124fa-19aa286b82d"
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

## Task 3
TLS/testssl summary:
Supported versions: TLS 1.2, TLS 1.3,

TLS 1.3:
- xc030   ECDHE-RSA-AES256-GCM-SHA384       (ECDH 256, AESGCM 256)
- xc02f   ECDHE-RSA-AES128-GCM-SHA256       (ECDH 256, AESGCM 128)


TLS 1.2:
- x1302   TLS_AES_256_GCM_SHA384            (ECDH 253, AESGCM 256)
- x1303   TLS_CHACHA20_POLY1305_SHA256      (ECDH 253, ChaCha20 256)
- x1301   TLS_AES_128_GCM_SHA256            (ECDH 253, AESGCM 128)

Why TLS 1.2+ is required
- TLS 1.3 is a priority - it provides better performance and security.
- Obsolete protocols are disabled - TLS 1.0/1.1 have known vulnerabilities.
- Perfect Forward Secrecy (PFS) - all ciphers support PFS.
- Modern algorithms - only AEAD ciphers (AES-GCM, ChaCha20).

Warning: 
- OCSP URI neither CRL nor OCSP URI provided
- OCSP stapling not offered

The following vulnerabilities were tested and none were found:
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
- Response 401 - 6 times
- Respomce 429 - 6 times

`rate=10r/m`: 10 requests per minute (1 request every 6 seconds on average)
`burst=5`: Allow up to 5 "burst" requests above the limit

Secures from brute-force attacks and files scanning.
Burst allows user make some fast requests.

client_body_timeout - Timeout for reading body of request. 
client_header_timeout - Timeout for reading head of request.
#### - protection against slow client attacks (Slowloris)

proxy_read_timeout - Backend read timeout.
proxy_send_timeout - Sending to backend timeout.

#### - protection from slow backend, prevents NGINX worker processes from blocking, allows processing of long operations