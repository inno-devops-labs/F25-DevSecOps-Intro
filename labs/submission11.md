# Task 1

### Explain why reverse proxies are valuable for security (TLS termination, security headers injection, request filtering, single access point)

**TLS termination**: reverse proxies handle TLS encryption/decryption and validation so that the app does not have to.

**Security headers injection**: reverse proxies can set response headers that help browsers block attacks.

**Request filtering**: validating requests so that the app does not have to handle every edge case; rate limiting
(against DoS attacks).

**Single access point**: reduces attack surface.

### Explain why hiding direct app ports reduces attack surface

If all HTTP requests have to pass through the reverse proxy, it becomes much harder to exploit the app because of the
validation that the proxy provides. It is simple to configure the reverse proxy once and connect it to the app, but it
is much more difficult to re-implement all the checks in the app itself and carefully monitor its exposed ports.

### `docker compose ps` output

NAME          | IMAGE                         | COMMAND                | SERVICE | CREATED            | STATUS            | PORTS
------------- | ----------------------------- | ---------------------- | ------- | ------------------ | ----------------- | ------
lab11-juice-1 | bkimminich/juice-shop:v19.0.0 | "/nodejs/bin/node /j…" | juice   | About a minute ago | Up About a minute | 3000/tcp
lab11-nginx-1 | nginx:stable-alpine           | "/docker-entrypoint.…" | nginx   | About a minute ago | Up About a minute | 0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp, 80/tcp, 0.0.0.0:8443->8443/tcp, [::]:8443->8443/tcp

Nginx makes the machine accept connections on ports 8080 and 8443 from all links on both IPv4 and IPv6. JuiceShop's port
3000 is inaccessible from the network.

# Task 2

- **X-Frame-Options**: Prevents embedding our website into other ones and scamming users into clicking something.
- **X-Content-Type-Options**: Forbids the browser to try to guess the filetype of a resource (so that an attacker cannot
  simply replace a .css file with a malicious script).
- **Strict-Transport-Security (HSTS)**: Makes the browser remember that this site must be accessed with HTTPS.
- **Referrer-Policy**: Only send juice shop's domain name in the `Referer` header to external sites when the user clicks
  a link or gets redirected. If the destination of the redirect is also juice shop, then send the full URL.
- **Permissions-Policy**: Denies using some invasive browser features by this site and all embedded ones.
- **COOP/CORP**: Prevents the browser from loading foreign resources in this page, even if they are sourced.
- **CSP-Report-Only**: Technically has no effect (`report-to` is not set); reports when resources of certain types are
  loaded from an undesirable origin.

# Task 3

## TLS/testssl summary:
### Summarize TLS protocol support from testssl scan (which versions are enabled)



### List cipher suites that are supported

### Explain why TLSv1.2+ is required (prefer TLSv1.3)

### Note any warnings or vulnerabilities from testssl output

### Confirm HSTS header appears only on HTTPS responses (not HTTP)

## Rate limiting & timeouts:
### Show rate-limit test output (how many 200s vs 429s)

Output:

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

6 `401 Unauthorized` (because there is no one registered as `a@a`) and 6 `429 Too Many Requests`.

### Explain the rate limit configuration: `rate=10r/m`, `burst=5`, and why these values balance security vs usability

10 requests per minute is reasonable for a normal use case (on average 1 request every 6 seconds), and up to 5 requests
can be sent in quick succession. On the other hand, the server can easily handle this frequency of requests, so
performing a (non-distributed) DoS attack becomes impossible with these restrictions.

### Explain timeout settings in nginx.conf: `client_body_timeout`, `client_header_timeout`, `proxy_read_timeout`, `proxy_send_timeout`, with trade-offs

| Timeout                      | Advantage of small time                                                 | Disadvantage of small time  |
| ---------------------------- | ----------------------------------------------------------------------- | --------------------------- |
| client_{header,body}_timeout | Slow clients do not hog connections                                     | Slow clients are not served |
| proxy_send_timeout           | If the app is overloaded and does not accept requests, they are dropped | System becomes unreliable   |
| proxy_read_timeout           | If the upstream connection is bad, a connection is freed                | System becomes unreliable   |

### Paste relevant lines from access.log showing 429 responses

In container `lab11-nginx-1`, in `/var/log/nginx/access.log`:
```
172.19.0.1 - - [10/Nov/2025:09:48:23 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.17.0" rt=0.000 uct=- urt=-
172.19.0.1 - - [10/Nov/2025:09:48:23 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.17.0" rt=0.000 uct=- urt=-
172.19.0.1 - - [10/Nov/2025:09:48:23 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.17.0" rt=0.000 uct=- urt=-
172.19.0.1 - - [10/Nov/2025:09:48:23 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.17.0" rt=0.000 uct=- urt=-
172.19.0.1 - - [10/Nov/2025:09:48:23 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.17.0" rt=0.000 uct=- urt=-
172.19.0.1 - - [10/Nov/2025:09:48:23 +0000] "POST /rest/user/login HTTP/2.0" 429 162 "-" "curl/8.17.0" rt=0.000 uct=- urt=-
```
