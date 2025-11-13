
# Lab 11 – Secure Reverse Proxy with Nginx and TLS

## 1. Goal of the Lab

In this lab I deployed OWASP Juice Shop behind an Nginx reverse proxy and added basic security controls:

- Terminate HTTPS on Nginx with a self-signed certificate.
- Enforce HTTP → HTTPS redirection.
- Verify TLS configuration with `testssl.sh`.
- Add simple rate limiting on the reverse proxy.
- Collect evidence (headers, scanner output, logs).

All steps were performed locally in Docker.

---

## 2. Setup and Configuration

### 2.1. Directory structure

I created the following structure for Lab 11:

- `labs/lab11/configs/` – TLS key and certificate:
  - `server.key`
  - `server.crt`
- `labs/lab11/reverse-proxy/`
  - `docker-compose.yml`
  - `nginx.conf`
- `labs/lab11/analysis/`
  - `headers-http.txt`
  - `headers-https.txt`
  - `testssl.txt`
  - `rate-limit-test.txt`

The directory `labs/lab11/analysis` contains all the evidence collected during the lab.

### 2.2. TLS certificate

I generated a self-signed certificate for `localhost`:

```bash
openssl req -x509 -newkey rsa:4096 -sha256 -nodes \
  -keyout labs/lab11/configs/server.key \
  -out labs/lab11/configs/server.crt \
  -days 365 \
  -subj "/CN=localhost"
````

This created a 4096-bit RSA key and a self-signed certificate valid for 1 year, used by Nginx for HTTPS termination.

---

## 3. Docker Compose and Nginx Reverse Proxy

### 3.1. `docker-compose.yml`

In `labs/lab11/reverse-proxy/docker-compose.yml` I defined two services:

```yaml
services:
  juice:
    image: bkimminich/juice-shop:v19.0.0
    container_name: juice11
    restart: always

  nginx:
    image: nginx:alpine
    container_name: nginx11
    depends_on:
      - juice
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ../configs/server.crt:/etc/nginx/certs/server.crt
      - ../configs/server.key:/etc/nginx/certs/server.key
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
```

Key points:

* Juice Shop runs as a backend on internal port `3000`.
* Nginx listens on host ports `80` and `443`.
* TLS key and certificate are mounted read-only into `/etc/nginx/certs/`.
* Nginx uses a custom `nginx.conf` from the lab directory.

### 3.2. `nginx.conf`

`labs/lab11/reverse-proxy/nginx.conf`:

```nginx
events {}

http {
    # Basic rate limiting
    limit_req_zone $binary_remote_addr zone=one:10m rate=5r/s;

    server {
        listen 80;
        server_name localhost;
        return 301 https://$host$request_uri;
    }

    server {
        listen 443 ssl;
        server_name localhost;

        ssl_certificate     /etc/nginx/certs/server.crt;
        ssl_certificate_key /etc/nginx/certs/server.key;

        location / {
            limit_req zone=one burst=10;
            proxy_pass http://juice:3000;
        }
    }
}
```

What this config does:

* **HTTP → HTTPS redirect**: the port 80 server always returns a `301` redirect to `https://…`.
* **TLS termination**: on port 443 Nginx terminates HTTPS using the self-signed cert.
* **Reverse proxy**: requests on `/` are proxied to the Juice Shop container (`http://juice:3000`).
* **Rate limiting**:

  * Defines a zone keyed by client IP: `limit_req_zone $binary_remote_addr zone=one:10m rate=5r/s;`
  * Applies it in the location: `limit_req zone=one burst=10;`

---

## 4. Evidence: HTTP/HTTPS Headers

I started the stack and collected headers with curl:

```bash
cd labs/lab11/reverse-proxy
docker compose up -d

mkdir -p ../analysis

# HTTP → HTTPS with redirect following
curl -I -L http://localhost \
  | tee ../analysis/headers-http.txt

# Direct HTTPS (self-signed, so -k)
curl -k -I https://localhost \
  | tee ../analysis/headers-https.txt
```

### 4.1. HTTP → HTTPS redirection

`headers-http.txt` shows:

```http
HTTP/1.1 301 Moved Permanently
Server: nginx/1.29.3
Location: https://localhost/
```

This confirms that plain HTTP is not served directly: all traffic on port 80 is redirected to HTTPS.

### 4.2. HTTPS response headers

`headers-https.txt` shows the final HTTPS response:

```http
HTTP/1.1 200 OK
Server: nginx/1.29.3
Content-Type: text/html; charset=UTF-8
Access-Control-Allow-Origin: *
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Feature-Policy: payment 'self'
Cache-Control: public, max-age=0
```

Observations:

* The response goes through Nginx (`Server: nginx/1.29.3`) and returns `200 OK`.
* Several security-related headers are present:

  * `X-Content-Type-Options: nosniff`
  * `X-Frame-Options: SAMEORIGIN`
  * `Feature-Policy: payment 'self'`
* **HSTS** (`Strict-Transport-Security`) is **not** present yet. This is a possible hardening step.

---

## 5. TLS Analysis with testssl.sh

To inspect the TLS configuration I ran `testssl.sh` against `https://localhost` from a container attached to the host network:

```bash
cd labs/lab11/reverse-proxy

docker run --rm --network host \
  drwetter/testssl.sh:latest https://localhost \
  | tee ../analysis/testssl.txt
```

### 5.1. Protocol support

From `testssl.txt`:

* **SSLv2**: not offered ✅
* **SSLv3**: not offered ✅
* **TLS 1.0 / 1.1**: not offered ✅
* **TLS 1.2**: offered ✅
* **TLS 1.3**: offered ✅

So the proxy only supports modern TLS versions (1.2 and 1.3), disabling legacy protocols.

### 5.2. Cipher suites and forward secrecy

`testssl.sh` reports:

* Strong AEAD ciphers (AES-GCM, ChaCha20) are available.
* Forward secrecy is offered with ECDHE key exchange.
* Some older CBC ciphers are still present for TLS 1.2, which leads to:

  * A **potential LUCKY13** warning (CBC + TLS).
  * This could be improved by explicitly disabling CBC ciphers in an advanced nginx TLS configuration.

### 5.3. Certificate and trust

`testssl.sh` output (summarised):

* Common Name: `localhost`
* Key size: **RSA 4096 bits**
* Chain of trust: **NOT OK (self-signed)**
* `subjectAltName` is missing, so modern browsers would complain.

This is expected for a self-signed lab certificate. In production, this should be replaced by a certificate issued by a trusted CA with proper SANs.

### 5.4. Security checks

Important vulnerability checks from `testssl.txt`:

* Heartbleed: **not vulnerable**
* CCS, FREAK, DROWN, LOGJAM, POODLE, SWEET32, RC4: **not vulnerable**
* BREACH: “potentially NOT ok” because HTTP compression is enabled – acceptable for this lab, but in a real application compression should be disabled on sensitive pages that include secrets.

Overall, the TLS configuration is modern and secure for a lab setup, with expected warnings related to self-signed certs and CBC/compression.

---

## 6. Rate Limiting Test and Logs

To exercise the rate limiting directive, I sent 50 quick requests to the proxy:

```bash
cd labs/lab11/reverse-proxy

for i in {1..50}; do
  curl -k -I https://localhost > /dev/null 2>&1
done

docker logs nginx11 | tee ../analysis/rate-limit-test.txt
```

`rate-limit-test.txt` contains many repeated `HEAD / HTTP/1.1` requests from the same client IP:

```text
172.20.0.1 - - [13/Nov/2025:20:22:11 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/8.5.0"
...
(many similar HEAD / requests)
...
```

With the current configuration:

```nginx
limit_req_zone $binary_remote_addr zone=one:10m rate=5r/s;
location / {
    limit_req zone=one burst=10;
    proxy_pass http://juice:3000;
}
```

* The limit is **5 requests per second** with a **burst of 10**.
* During my test, all responses were `200 OK`; no `429` or `503` rate-limit errors were observed in the logs.
* This is consistent with Nginx’s behavior: with `rate=5r/s` and `burst=10`, short spikes are allowed and excess requests are delayed rather than immediately rejected.

**How to harden further (optional):**

* Reduce `burst` or add `nodelay` / `status=429` to make abusive traffic clearly visible in the logs and to the client.
* Example (not applied in this lab, just as a recommendation):

```nginx
limit_req zone=one burst=5 nodelay;
```

This would make rate limiting much more aggressive and easier to demonstrate with 50 rapid requests.

---

## 7. Summary and Lessons Learned

In this lab I:

1. Deployed OWASP Juice Shop behind an Nginx reverse proxy.
2. Generated and used a self-signed 4096-bit RSA certificate for HTTPS termination.
3. Enforced HTTP → HTTPS redirection (confirmed by `headers-http.txt`).
4. Verified TLS configuration with `testssl.sh`:

   * Only TLS 1.2 and 1.3 are enabled.
   * Strong ciphers and forward secrecy are supported.
   * Self-signed cert and missing SAN produce expected trust warnings.
5. Implemented basic client IP–based rate limiting in Nginx and collected logs with multiple rapid requests.

Potential improvements for a production-grade setup:

* Use a trusted CA certificate with SANs instead of a self-signed cert.
* Enable HSTS (`Strict-Transport-Security`) to enforce HTTPS at the browser level.
* Disable CBC ciphers and consider disabling compression on sensitive pages to avoid LUCKY13/BREACH-style issues.
* Tune rate limiting parameters and return codes (e.g. `429 Too Many Requests`) for clearer visibility and stronger protection.
