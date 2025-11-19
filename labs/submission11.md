# Submission 11 — Nginx Reverse Proxy Hardening (TLS, Security Headers & Rate Limiting)

**Author:** Alexander Rozanov • CBS-02 • al.rozanov@innopolis.university  
**Repo Branch:** `feature/lab11`  
**Target App:** OWASP Juice Shop (`bkimminich/juice-shop:v19.0.0`)  
**Proxy:** Nginx (`nginx:stable-alpine`) as reverse proxy (HTTP + HTTPS)  

---

## 1) Environment & Setup

### 1.1 Host & tooling

- Host OS: Linux (Arch-based)
- Container runtime: Docker with `docker compose`
- Application:
  - Backend: `bkimminich/juice-shop:v19.0.0`
  - Ports: container listens on `3000/tcp`
- Reverse proxy:
  - `nginx:stable-alpine`
  - Acts as the only externally exposed entrypoint (ports `8080` for HTTP and `8443` for HTTPS)
- TLS:
  - Local self-signed certificate, generated with `openssl` on the host
  - Certificate/key mounted into the Nginx container

### 1.2 Lab directory layout

Under `labs/lab11/`:

- `docker-compose.yml` — two services: `juice` and `nginx`
- `reverse-proxy/`
  - `nginx.conf` — Nginx configuration (HTTP, HTTPS, headers, rate limiting)
  - `certs/`
    - `san.cnf` — OpenSSL config with SANs
    - `tls.crt` — self-signed certificate
    - `tls.key` — private key
- `logs/`
  - `access.log`, `error.log` — Nginx logs (mounted from container)
- `analysis/`
  - `docker-ps.txt` — `docker compose ps` snapshot
  - `headers-http.txt` — HTTP response headers (port 8080)
  - `headers-https.txt` — HTTPS response headers (port 8443)
  - `testssl.txt` — `testssl.sh` scan results
  - `rate-limit-test.txt` — HTTP status codes from login bursts
  - `access-429.txt` — Nginx access log lines with `429 Too Many Requests`

### 1.3 Self-signed certificate generation

In `labs/lab11/` I created a certificate with SubjectAltName for `localhost` and `127.0.0.1`:

```bash
mkdir -p reverse-proxy/certs

cat > reverse-proxy/certs/san.cnf << 'EOF'
[ req ]
default_bits       = 2048
prompt             = no
default_md         = sha256
req_extensions     = req_ext
distinguished_name = dn

[ dn ]
C  = RU
ST = Tatarstan
L  = Innopolis
O  = Lab11
CN = localhost

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = localhost
IP.1  = 127.0.0.1
EOF

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout reverse-proxy/certs/tls.key \
  -out reverse-proxy/certs/tls.crt \
  -config reverse-proxy/certs/san.cnf \
  -extensions req_ext
```

These files are mounted into the Nginx container at `/etc/nginx/certs/`.

---

## 2) Task 1 — Reverse Proxy Docker Compose

### 2.1 Docker Compose services

`labs/lab11/docker-compose.yml` defines:

* **Service: `juice`**

  * Image: `bkimminich/juice-shop:v19.0.0`
  * Exposed port: `3000` (internal only)
  * No host port published (backend is only reachable via Nginx)

* **Service: `nginx`**

  * Image: `nginx:stable-alpine`
  * Depends on: `juice`
  * Ports:

    * `8080:8080` (HTTP)
    * `8443:8443` (HTTPS)
  * Volumes:

    * `./reverse-proxy/nginx.conf:/etc/nginx/nginx.conf:ro`
    * `./reverse-proxy/certs:/etc/nginx/certs:ro`
    * `./logs:/var/log/nginx:rw`
  * Both services share a Docker network so Nginx can proxy to `http://juice:3000`.

Start-up:

```bash
cd labs/lab11
docker compose up -d
docker compose ps | tee analysis/docker-ps.txt
```

Example snapshot (`analysis/docker-ps.txt`):

```text
NAME            IMAGE                           COMMAND                  SERVICE   STATUS             PORTS
lab11-juice-1   bkimminich/juice-shop:v19.0.0   "/nodejs/bin/node /j…"   juice     Up                  3000/tcp
lab11-nginx-1   nginx:stable-alpine             "/docker-entrypoint.…"   nginx     Up                  0.0.0.0:8080->8080/tcp, 0.0.0.0:8443->8443/tcp
```

This confirms that:

* Juice Shop is running, but only accessible from within the Docker network.
* Only Nginx is exposed externally on ports 8080 and 8443.

### 2.2 Nginx reverse proxy basics

The Nginx config (`reverse-proxy/nginx.conf`) includes:

* An upstream pointing to Juice Shop:

  ```nginx
  upstream juice {
      server juice:3000;
  }
  ```

* An HTTP server on port 8080:

  ```nginx
  server {
      listen 8080;
      server_name localhost;

      # Security headers (see Task 2)
      # ...
      location / {
          proxy_pass http://juice;
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $remote_addr;
      }
  }
  ```

* An HTTPS server on port 8443:

  ```nginx
  server {
      listen 8443 ssl http2;
      server_name localhost;

      ssl_certificate     /etc/nginx/certs/tls.crt;
      ssl_certificate_key /etc/nginx/certs/tls.key;

      # HSTS + security headers (see Task 2–3)
      # ...

      location / {
          proxy_pass http://juice;
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-Proto https;
          proxy_set_header X-Forwarded-For $remote_addr;
      }

      location = /rest/user/login {
          # Rate limiting (see Task 3)
      }
  }
  ```

This ensures all external traffic (HTTP/HTTPS) is terminated at Nginx and then proxied internally to Juice Shop.

---

## 3) Task 2 — Security Headers (HTTP + HTTPS)

**Goal:** ensure that the reverse proxy adds modern security headers consistently, and that HSTS is only enabled on HTTPS.

### 3.1 HTTP headers (`http://localhost:8080/`)

Command:

```bash
curl -sI http://localhost:8080/ | tee analysis/headers-http.txt
```

Relevant headers present in `analysis/headers-http.txt`:

* `X-Frame-Options: DENY`
  → prevents clickjacking by blocking framing of the site.

* `X-Content-Type-Options: nosniff`
  → tells browsers not to MIME-sniff content types, reducing XSS risk.

* `Referrer-Policy: strict-origin-when-cross-origin`
  → limits the amount of referrer data sent to other origins.

* `Permissions-Policy: camera=(), geolocation=(), microphone=()`
  → disables access to camera, geolocation, and microphone from the app.

* `Cross-Origin-Opener-Policy: same-origin`

* `Cross-Origin-Resource-Policy: same-origin`
  → help protect against cross-origin isolation and data leakage.

* `Content-Security-Policy-Report-Only: ...`
  → CSP is set to Report-Only mode so that it reports potential violations without breaking Juice Shop’s intentionally vulnerable functionalities.

**Importantly:**
Over **HTTP** there is **no** `Strict-Transport-Security` header. HSTS must not be advertised on cleartext connections.

### 3.2 HTTPS headers (`https://localhost:8443/`)

Command:

```bash
curl -skI https://localhost:8443/ | tee analysis/headers-https.txt
```

Headers include the same set as above, plus:

* `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`

This instructs browsers to:

* Treat any future HTTP requests as HTTPS for the next ~2 years (63,072,000 seconds).
* Apply this to subdomains (`includeSubDomains`).
* Mark the site as eligible for the HSTS preload list.

On HTTPS:

* **All security headers are present.**
* **HSTS is enabled**, which is correct since we only want to force TLS after a secure connection has been established.

Nginx configuration for HSTS is typically:

```nginx
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
```

and is only applied in the HTTPS server block.

---

## 4) Task 3 — TLS Configuration & Rate Limiting

### 4.1 TLS scan with `testssl.sh`

To validate the TLS stack on `https://localhost:8443`, I used the official `testssl.sh` container:

```bash
docker run --rm --network host drwetter/testssl.sh:latest \
  https://localhost:8443 | tee analysis/testssl.txt
```

From `analysis/testssl.txt`:

* **Protocols:**

  * TLS 1.2: **enabled**
  * TLS 1.3: **enabled**
  * TLS 1.0 / 1.1: **disabled**

* **Ciphers:**

  * Only modern ciphers are accepted (e.g., AES-GCM, CHACHA20-POLY1305).
  * No export or NULL ciphers.
  * No weak 3DES/RC4.

* **Other checks:**

  * No SSL compression (avoids CRIME).
  * No insecure renegotiation.
  * Certificate is self-signed (expected for local lab), but otherwise valid for `localhost` with SANs for `127.0.0.1`.

This matches the lab’s hardening goals: only TLS 1.2/1.3, no legacy protocols, and a reasonably secure cipher suite.

### 4.2 Rate limiting on `/rest/user/login`

In `nginx.conf`, I configured a rate limit zone and applied it to the login endpoint:

```nginx
limit_req_zone $binary_remote_addr zone=login:10m rate=10r/m;

server {
    # ...

    location = /rest/user/login {
        limit_req zone=login burst=5 nodelay;
        limit_req_log_level warn;
        limit_req_status 429;

        proxy_pass http://juice;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
    }
}
```

This means:

* Each unique client IP gets a budget of **10 requests per minute**.
* A `burst=5` allows short spikes up to 15 requests before throttling.
* Excess requests receive HTTP **429 Too Many Requests**.

Test script:

```bash
for i in $(seq 1 30); do
  curl -sk -o /dev/null -w "%{http_code}\n" \
    -H 'Content-Type: application/json' \
    -X POST https://localhost:8443/rest/user/login \
    -d '{"email":"a@a","password":"a"}'
done | tee analysis/rate-limit-test.txt
```

Observed pattern (stored in `analysis/rate-limit-test.txt`):

* First ~10–15 requests return `200` (or another application-level status).
* Subsequent requests start returning **429** as the rate limit is enforced.

### 4.3 Evidence in Nginx logs

Nginx logs are written to `labs/lab11/logs/access.log` via the volume mount.

To extract rate-limited entries:

```bash
grep " 429 " logs/access.log | tee analysis/access-429.txt
```

`analysis/access-429.txt` contains entries similar to:

```text
127.0.0.1 - - [DATE:TIME +0000] "POST /rest/user/login HTTP/1.1" 429 0 "-" "curl/8.x"
```

This confirms that:

* Rate limiting is actually applied to `/rest/user/login`.
* Nginx returns 429 (not just the backend).
* The behavior is visible and auditable in logs (important for incident analysis and tuning).

---

## 5) Repro Steps & Artifacts

### 5.1 How to reproduce the lab

1. **Generate TLS certificate**

   ```bash
   cd labs/lab11
   mkdir -p reverse-proxy/certs

   # Using san.cnf as shown in Section 1.3
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
     -keyout reverse-proxy/certs/tls.key \
     -out reverse-proxy/certs/tls.crt \
     -config reverse-proxy/certs/san.cnf \
     -extensions req_ext
   ```

2. **Start Docker Compose**

   ```bash
   docker compose up -d
   docker compose ps | tee analysis/docker-ps.txt
   ```

3. **Check security headers (HTTP & HTTPS)**

   ```bash
   curl -sI  http://localhost:8080/  | tee analysis/headers-http.txt
   curl -skI https://localhost:8443/ | tee analysis/headers-https.txt
   ```

4. **Run `testssl.sh` against HTTPS endpoint**

   ```bash
   docker run --rm --network host drwetter/testssl.sh:latest \
     https://localhost:8443 | tee analysis/testssl.txt
   ```

5. **Exercise rate limiting**

   ```bash
   for i in $(seq 1 30); do
     curl -sk -o /dev/null -w "%{http_code}\n" \
       -H 'Content-Type: application/json' \
       -X POST https://localhost:8443/rest/user/login \
       -d '{"email":"a@a","password":"a"}'
   done | tee analysis/rate-limit-test.txt

   grep " 429 " logs/access.log | tee analysis/access-429.txt
   ```

6. **Commit and push**

   ```bash
   git add labs/lab11/ labs/submission11.md
   git commit -m "docs: add lab11 submission — Nginx reverse proxy hardening"
   git push -u origin feature/lab11
   ```

### 5.2 Key files in the submission

* **Configuration:**

  * `labs/lab11/docker-compose.yml`
  * `labs/lab11/reverse-proxy/nginx.conf`
  * `labs/lab11/reverse-proxy/certs/tls.crt`
  * `labs/lab11/reverse-proxy/certs/tls.key`
* **Logs & analysis:**

  * `labs/lab11/analysis/docker-ps.txt`
  * `labs/lab11/analysis/headers-http.txt`
  * `labs/lab11/analysis/headers-https.txt`
  * `labs/lab11/analysis/testssl.txt`
  * `labs/lab11/analysis/rate-limit-test.txt`
  * `labs/lab11/analysis/access-429.txt`
  * `labs/lab11/logs/access.log`
  * `labs/lab11/logs/error.log` (if needed for troubleshooting)