# Lab 11 Submission — Nginx Reverse Proxy Hardening

## Task 1 — Reverse Proxy Compose Setup

### Why a reverse proxy improves security

A reverse proxy such as Nginx is an important security control in front of a web application:

* **TLS termination**  
  Nginx terminates HTTPS, performs encryption and decryption, and then forwards plain HTTP traffic to the application inside the Docker network. TLS settings are managed in one place, which reduces the risk of mistakes in the application and simplifies key and certificate rotation.

* **Injection of security headers**  
  The reverse proxy can inject and enforce security headers such as HSTS, Content Security Policy, X Frame Options, and X Content Type Options for every response. These headers add protection against clickjacking, content type confusion, downgrade attacks, and some categories of cross site scripting.

* **Request filtering and basic DoS protection**  
  Nginx can filter dangerous or malformed requests, limit request size, restrict HTTP methods, and block obvious attack patterns. It can also provide basic protection against slow or abusive clients by combining rate limits with timeouts.

* **Single entry point**  
  All external traffic goes through Nginx. This central point simplifies monitoring, logging, auditing, and enforcement of security policy. It is easier to reason about one hardened entry point than multiple application instances exposed directly.

### Why hiding direct app ports reduces the attack surface

If OWASP Juice Shop is exposed directly to the internet, an attacker can:

* scan the app port and identify the service
* probe built in endpoints for known vulnerabilities in Juice Shop
* try brute force or fuzzing attacks directly against the app
* bypass security filters at the edge

When the Juice Shop container listens only on an internal Docker network and the host exposes only the Nginx ports:

* direct exploitation of the app from outside is not possible
* all external clients interact only with Nginx, not with Juice Shop directly
* the app is not visible during port scanning from outside
* Nginx can apply security headers, rate limits, and timeouts for every request

This design removes a direct network path to the application and therefore reduces the attack surface.

### docker compose ps output

The `docker compose ps` output shows that only Nginx exposes host ports, while Juice Shop is internal only:

```text
NAME            IMAGE                           COMMAND                  SERVICE   CREATED         STATUS         PORTS
lab11-juice-1   bkimminich/juice-shop:v19.0.0   "/nodejs/bin/node /j…"   juice     9 seconds ago   Up 9 seconds   3000/tcp
lab11-nginx-1   nginx:stable-alpine             "/docker-entrypoint.…"   nginx     9 seconds ago   Up 8 seconds   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp, 80/tcp, 0.0.0.0:8443->8443/tcp, [::]:8443->8443/tcp
```

* `lab11-nginx-1` publishes ports `8080` and `8443` on the host. This is expected because Nginx is the public entry point.
* `lab11-juice-1` shows `3000/tcp` with no host binding. There is no `0.0.0.0:` mapping. Juice Shop listens on port 3000 only inside the Docker network and is reachable only through the Nginx reverse proxy.

---

## Task 2 — Analysis of Security Headers

This section analyses the security related HTTP response headers from the Nginx server over HTTPS (`https://localhost:8443`) and over HTTP before redirect (`http://localhost:8080`).

### Security headers over HTTPS

Command:

```bash
curl -skI https://localhost:8443/
```

Relevant response headers:

```text
strict-transport-security: max-age=31536000 includeSubDomains preload
x-frame-options: DENY
x-content-type-options: nosniff
referrer-policy: strict-origin-when-cross-origin
permissions-policy: camera=() geolocation=() microphone=()
cross-origin-opener-policy: same-origin
cross-origin-resource-policy: same-origin
content-security-policy-report-only: default-src 'self' img-src 'self' data: script-src 'self' 'unsafe-inline' 'unsafe-eval' style-src 'self' 'unsafe-inline'
```

### Explanation of each header

#### Strict Transport Security

Header:

```text
strict-transport-security: max-age=31536000 includeSubDomains preload
```

* `max-age=31536000` means the browser should remember the HSTS policy for one year.
* `includeSubDomains` extends HSTS to all subdomains.
* `preload` indicates that the site can be added to browser preload lists.

Effect -> forces browsers to use HTTPS for all future connections and blocks the user from overriding certificate errors. This protects against protocol downgrade and SSL stripping attacks.

#### X Frame Options

Header:

```text
x-frame-options: DENY
```

* Tells the browser to never render this site inside an `iframe` or similar frame.

Effect -> mitigates clickjacking attacks where an attacker tries to trick a user into clicking hidden elements inside a frame.

#### X Content Type Options

Header:

```text
x-content-type-options: nosniff
```

* Tells the browser not to guess or sniff MIME types and instead trust the declared `Content-Type`.

Effect -> prevents attacks that rely on the browser interpreting data as a different type, such as scripts served with a non script content type.

#### Referrer Policy

Header:

```text
referrer-policy: strict-origin-when-cross-origin
```

* For same origin navigation, the full URL is sent as the `Referer`.
* For cross origin requests, only the scheme, host, and port (the origin) are sent.

Effect -> provides a balance between privacy and usability. It limits leakage of path and query data while still allowing enough information for analytics and debugging.

#### Permissions Policy

Header:

```text
permissions-policy: camera=() geolocation=() microphone=()
```

* Forbids the use of camera, geolocation, and microphone APIs in the context of this site.

Effect -> adds defense in depth for sensitive browser features. Even if application code tries to request these permissions, the browser denies them.

#### Cross Origin Opener Policy

Header:

```text
cross-origin-opener-policy: same-origin
```

* Isolates the browsing context so windows or tabs from other origins do not share the same browsing context group.

Effect -> mitigates some cross origin side channel and cross site leaks. It is part of modern cross origin isolation strategies.

#### Cross Origin Resource Policy

Header:

```text
cross-origin-resource-policy: same-origin
```

* Tells the browser that only same origin pages are allowed to load resources from this origin.

Effect -> prevents other sites from loading resources in a way that could leak data.

#### Content Security Policy Report Only

Header:

```text
content-security-policy-report-only: default-src 'self' img-src 'self' data: script-src 'self' 'unsafe-inline' 'unsafe-eval' style-src 'self' 'unsafe-inline'
```

Interpretation:

* `default-src 'self'` means that by default, resources must come from the same origin.
* `img-src 'self' data:` allows images from the same origin and from data URLs.
* `script-src 'self' 'unsafe-inline' 'unsafe-eval'` allows scripts from the same origin and still allows inline script and dynamic eval.
* `style-src 'self' 'unsafe-inline'` allows styles from the same origin and inline style.

The header is in **Report Only** mode. Browsers do not block violations but send reports instead. This is a safe way to test a policy on a JavaScript heavy application such as Juice Shop.

Effect -> provides monitoring and a starting point for CSP hardening. Once inline script and inline style can be removed or refactored, the policy can be turned into an enforcing CSP for stronger protection against cross site scripting.

### Security headers over HTTP (before redirect)

Command:

```bash
curl -sI http://localhost:8080/
```

Relevant response:

```text
HTTP/1.1 308 Permanent Redirect
Location: https://localhost:8443/
x-frame-options: DENY
x-content-type-options: nosniff
referrer-policy: strict-origin-when-cross-origin
permissions-policy: camera=() geolocation=() microphone=()
cross-origin-opener-policy: same-origin
cross-origin-resource-policy: same-origin
content-security-policy-report-only: default-src 'self' img-src 'self' data: script-src 'self' 'unsafe-inline' 'unsafe-eval' style-src 'self' 'unsafe-inline'
```

Comments:

* HTTP responds with a permanent redirect (308) to HTTPS.
* Most security headers are also included on the HTTP redirect, which is good practice.
* HSTS is not included on the HTTP response, which is correct because browsers ignore HSTS received over plain HTTP.

### Summary for Task 2

The Nginx configuration:

* Redirects all HTTP traffic to HTTPS.
* Adds multiple defensive headers:
  * HSTS
  * X Frame Options
  * X Content Type Options
  * Referrer Policy
  * Permissions Policy
  * Cross origin opener policy
  * Cross origin resource policy
  * Content Security Policy in report only mode

The main remaining improvement is to tighten CSP and remove inline script and inline style once the application supports that.

---

## Task 3 — TLS, HSTS, Rate Limiting and Timeouts

### TLS and testssl summary

TLS was scanned with `testssl.sh`:

```bash
docker run --rm --network host drwetter/testssl.sh:latest https://localhost:8443   | tee analysis/testssl.txt
```

#### Protocol support

From the scan:

* TLS 1.2 is offered.
* TLS 1.3 is offered in its final version.
* SSLv2, SSLv3, TLS 1.0, and TLS 1.1 are not offered, which is the desired outcome.

Requiring at least TLS 1.2 ensures strong encryption and support for modern cipher suites. TLS 1.3 also gives faster handshakes and a more secure protocol design.

#### Cipher suites

Supported cipher suites include:

* For TLS 1.2 (server order):
  * ECDHE RSA AES256 GCM SHA384
  * ECDHE RSA AES128 GCM SHA256
* For TLS 1.3 (server order):
  * TLS AES 256 GCM SHA384
  * TLS CHACHA20 POLY1305 SHA256
  * TLS AES 128 GCM SHA256

These suites provide:

* authenticated encryption with Galois Counter Mode or ChaCha20 Poly1305
* forward secrecy due to ECDHE or equivalent key agreement
* strong key sizes

Forward secrecy is explicitly reported as offered with these suites.

Elliptic curves offered include:

* prime256v1
* secp384r1
* secp521r1
* X25519
* X448

These are standard modern curves suitable for secure ECDHE exchanges.

#### Why TLS 1.2 and 1.3 are required

Older protocols such as SSLv3 and TLS 1.0 or 1.1 are vulnerable to attacks such as POODLE and BEAST and can require weak ciphers. Disabling them reduces exposure to legacy downgrade attacks.

TLS 1.2 and especially TLS 1.3:

* support strong ciphers only
* improve performance and latency
* reduce protocol complexity and known weaknesses

Therefore enforcing TLS 1.2 or newer is a best practice for public services.

#### Warnings and expected issues from testssl

With a self signed certificate for `localhost`, testssl reports issues such as:

* chain of trust not ok because the certificate is not signed by a public or trusted CA
* OCSP, CRL, certificate transparency, and CAA checks not available or not configured
* OCSP stapling disabled

On `localhost` in a lab environment this is expected. For production, the following changes are required:

* use a certificate issued by a trusted CA such as a public CA or an internal corporate CA
* configure OCSP stapling and possibly CRL distribution
* configure CAA records and certificate transparency where applicable

The scan does not show major active TLS vulnerabilities such as Heartbleed, CCS injection, FREAK, DROWN, SWEET32, or BEAST.

#### HSTS behavior

As shown in Task 2:

* The HSTS header appears on HTTPS responses.

```text
strict-transport-security: max-age=31536000 includeSubDomains preload
```

* HSTS is not present on HTTP responses, which only return a redirect.

This behavior is correct because browsers use HSTS only when it is received over an HTTPS connection.

### Rate limiting on login

Rate limiting is configured on the login endpoint `/rest/user/login` using Nginx `limit_req` with `limit_req_status 429`.

#### Rate limit test output

Command:

```bash
for i in $(seq 1 12)
do
  curl -sk -o /dev/null -w "%{http_code}\n"     -H 'Content-Type: application/json'     -X POST https://localhost:8443/rest/user/login     -d '{"email":"a@a","password":"a"}'
done | tee analysis/rate-limit-test.txt
```

Observed HTTP status codes:

```text
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

Interpretation:

* The first six requests returned `401` (unauthorized) due to invalid credentials.
* After the configured threshold was exceeded, the next six requests returned `429` (too many requests), which confirms that the rate limit is active.

#### Access log entries for 429 responses

Relevant Nginx access log lines:

```text
172.18.0.1 - - [21/Nov/2025:12:26:56 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.5.0" rt=0.000 uct=- urt=-
172.18.0.1 - - [21/Nov/2025:12:26:56 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.5.0" rt=0.000 uct=- urt=-
172.18.0.1 - - [21/Nov/2025:12:26:56 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.5.0" rt=0.000 uct=- urt=-
172.18.0.1 - - [21/Nov/2025:12:26:56 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.5.0" rt=0.000 uct=- urt=-
172.18.0.1 - - [21/Nov/2025:12:26:56 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.5.0" rt=0.000 uct=- urt=-
172.18.0.1 - - [21/Nov/2025:12:26:56 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.5.0" rt=0.000 uct=- urt=-
```

These entries confirm that the login endpoint returned HTTP 429 during the test, with very short response times, which is expected for rate limiting at the proxy.

#### Rate limit configuration and trade offs

The relevant Nginx configuration is:

```text
limit_req_zone $binary_remote_addr zone=login:10m rate=10r/m
...
limit_req zone=login burst=5 nodelay
```

Meaning per client IP:

* average rate of ten requests per minute
* a burst of five extra requests is allowed
* once the burst is exhausted, further requests are answered with `429`

Trade offs:

* **Security**  
  This slows down brute force attempts against the login endpoint and reduces log noise from automated tools.
* **Usability**  
  Legitimate users rarely send more than a few login requests per minute, so values of ten per minute with a burst of five allow for occasional mistakes or retries without blocking normal use.
* **Performance**  
  Rate limiting at the edge can protect the backend from unnecessary work, but aggressive limits can frustrate users if configured too strictly.

The chosen numbers give a reasonable baseline that prevents obvious abuse while remaining usable for normal clients.

### Timeout settings in Nginx

Important timeout directives in `nginx.conf` include:

* `client_body_timeout 10s`  
  Nginx waits at most ten seconds for the request body. If the client is too slow, Nginx closes the connection. This protects against slow upload attacks, but very slow clients might be cut off.

* `client_header_timeout 10s`  
  Nginx waits ten seconds for request headers. This prevents slowloris style attacks where the attacker sends headers extremely slowly to tie up connections.

* `proxy_read_timeout 30s`  
  Nginx waits up to thirty seconds for a response from the upstream application. If the backend is slow, the client receives an error after that. A shorter timeout reduces the risk of many hanging connections but can break long running requests.

* `proxy_send_timeout 30s`  
  Nginx waits up to thirty seconds to send a request to the upstream application. A slow upstream or network issue can trigger a timeout here.

Trade offs:

* Shorter timeouts improve resilience against slow attacks that hold connections open for a long time with minimal traffic.
* Longer timeouts are better for slow networks and long running responses.
* The chosen values provide a balance. They are long enough for normal web traffic yet short enough to reduce the impact of resource exhaustion attacks.
