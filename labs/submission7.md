# Lab 7 - Container Security: Image Scanning & Deployment Hardening
## Task 1 - Image Vulnerability & Configuration Analysis

### 1.1 Top 5 Critical/High Vulnerabilities

Using **Docker Scout** and **Snyk**, the image `bkimminich/juice-shop:v19.0.0` was found to contain numerous critical and high-severity issues across common npm libraries.

| # | CVE ID | Package | Severity | Description / Impact |
|:-:|:-------|:---------|:----------|:----------------------|
| 1 | **CVE-2023-37903** | `vm2 3.9.17` | Critical (9.8) | OS command injection in the sandbox engine vm2 allows remote code execution on the container. No fix available → high risk of RCE. |
| 2 | **CVE-2019-10744** | `lodash 2.4.2` | Critical (9.1) | Prototype pollution lets attackers modify application objects and execute arbitrary logic → potential data manipulation or XSS. |
| 3 | **CVE-2015-9235** | `jsonwebtoken 0.1.0` | Critical | Improper input validation allows token forgery and authentication bypass → users could access resources without valid credentials. |
| 4 | **CVE-2021-44906** | `minimist 0.2.4` | Critical (9.8) | Argument parsing flaw enables arbitrary property injection leading to remote code execution if untrusted input is passed to CLI. |
| 5 | **CVE-2023-46233** | `crypto-js 3.3.0` | Critical (9.1) | Use of weak cryptographic algorithms permits message tampering and compromised encryption → loss of confidentiality and integrity. |


---

### 1.2 Dockle Configuration Findings

| Level | Finding (ID) | Explanation / Risk |
|:------|:--------------|:-------------------|
| **INFO** | `CIS-DI-0005 – Enable Content Trust` | Image build/pull was done without `DOCKER_CONTENT_TRUST=1`; unsigned images can be tampered with in transit. |
| **INFO** | `CIS-DI-0006 – Add HEALTHCHECK instruction` | No `HEALTHCHECK` statement in Dockerfile → orchestrators cannot detect unhealthy containers automatically. |
| **INFO** | `DKL-LI-0003 – Only put necessary files` | Unnecessary `.DS_Store` files increase image size and leak metadata. They should be excluded using `.dockerignore`. |

Although Dockle reported no FATAL or WARN items in this scan, these informational findings reveal **missing best practices** that reduce image trust and manageability.

---

### 1.3 Security Posture Assessment of `bkimminich/juice-shop:v19.0.0`

| Aspect | Observation | Risk |
|:--------|:-------------|:-----|
| **Default user** | Runs as root (by default Dockerfile configuration) | Privilege escalation if the app is exploited. |
| **Secrets in env vars** | Contains challenge flags and CTF keys visible in environment → exposed sensitive data. | Information disclosure. |
| **Outdated packages** | Packages like `vm2`, `lodash`, `jsonwebtoken`, `crypto-js` are years old with unfixed CVEs. | RCE / Auth bypass / Weak crypto. |
| **Hardening controls** | No user or HEALTHCHECK directive, no read-only root FS, no capability drops. | Poor runtime isolation. |

**Overall Risk:** **High**

**Recommended Mitigations**
1. Rebuild image from patched base (e.g. `node:18-alpine`) and update npm dependencies.  
2. Add `USER node` to run as non-root.  
3. Include `HEALTHCHECK` for service availability monitoring.  
4. Use `--cap-drop=ALL` and `--security-opt=no-new-privileges` at runtime.  
5. Sign and verify images (`DOCKER_CONTENT_TRUST=1`).  
6. Scan images regularly in CI/CD to catch new CVEs early.

## Task 2 - Docker Host Security Benchmarking

Bash command doesn't work

```logs
tee: hardening/docker-bench-results.txt: No such file or directory
docker: Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: error mounting "/var/lib/docker/containers/9ba47a4588d1ac0f27821885a04f574ec3609a340ff8eab10943fed0f388b574/hostname" to rootfs at "/etc/hostname": create mountpoint for /etc/hostname mount: create target of file bind-mount: mknod regular file /var/lib/docker/overlay2/f8a325583af0f498caadeb2a3f1c000a6f18160bc5068f5cd73c529ae8c44a29/merged/etc/hostname: read-only file system: unknown
```

## Task 3 - Deployment Security Configuration Analysis

### 3.1 Profile Comparison

All three containers (`juice-default`, `juice-hardened`, and `juice-production`) successfully responded with HTTP 200, confirming functional equivalence despite different security restrictions.

| Profile | Capabilities | Security Options | Memory | CPU Limit | PIDs Limit | Restart Policy |
|----------|---------------|------------------|---------|------------|-------------|----------------|
| **Default** | None dropped | None | Unlimited | Unlimited | None | None |
| **Hardened** | `--cap-drop=ALL` | `no-new-privileges` | 512 MB | 1 CPU | None | None |
| **Production** | `--cap-drop=ALL` | `no-new-privileges`, *(Docker default seccomp applied)* | 512 MB | 1 CPU | 100 | `on-failure:3` |

**Resource usage (from `docker stats`):**
- Default: ~106 MiB RAM, ~2% CPU  
- Hardened: ~94 MiB RAM, ~0.6% CPU  
- Production: ~93 MiB RAM, ~0.56% CPU  

---

### 3.2 Security Measure Analysis

#### a) `--cap-drop=ALL` / `--cap-add=NET_BIND_SERVICE`
- **What it does:** Linux capabilities split root privileges into small units. Dropping all removes dangerous powers (e.g. `SYS_ADMIN`, `NET_RAW`, `CHOWN`).
- **Security benefit:** Prevents compromised processes from manipulating network stack, kernel modules, or filesystem mounts.
- **Why `NET_BIND_SERVICE`:** Allows non-root app to bind to ports < 1024 (e.g. 80, 443) without full root rights.
- **Trade-off:** If app or library expects additional capabilities (e.g. `DAC_OVERRIDE`), it may fail; rarely an issue for web apps.

#### b) `--security-opt=no-new-privileges`
- **Effect:** Prevents processes inside the container from gaining extra privileges via setuid binaries or file capabilities.
- **Attack mitigated:** Stops privilege escalation after initial exploit or lateral movement attempts.
- **Trade-off:** Breaks programs that rely on setuid escalation (like `sudo`); not relevant for production workloads.

#### c) `--memory=512m`, `--memory-swap=512m`, `--cpus=1.0`
- **Purpose:** Constrains container resource use.
- **Benefit:** Protects the host and other workloads from denial-of-service due to runaway memory/CPU usage.
- **Risk:** If set too low, the app can be OOM-killed under high traffic.

#### d) `--pids-limit=100`
- **Purpose:** Caps number of processes the container can spawn.
- **Benefit:** Prevents “fork bomb”–style denial-of-service that would exhaust host PID table.
- **Trade-off:** Too strict a limit may break apps using many child processes (e.g. Node worker threads).

#### e) `--restart=on-failure:3`
- **Purpose:** Auto-restarts a crashed service up to 3 times.
- **Benefit:** Improves resilience against transient errors or brief outages.
- **Risk:** Persistent crash loops can mask faults or waste resources if health monitoring is not configured.

---

### 3.3 Critical Thinking

**1. Best profile for DEVELOPMENT:**  
_Default profile._  
Developers need fast iteration and debugging. Relaxed limits allow attaching debuggers, editing files, and running interactive tools.

**2. Best profile for PRODUCTION:**  
_Production profile._  
Implements least privilege, enforces resource isolation, and adds resiliency through restart policy - minimizing impact of compromise.

**3. Real-world problem solved by resource limits:**  
Prevents any single compromised or malfunctioning container from consuming all host resources and degrading other services - critical in multi-tenant or CI/CD hosts.

**4. Difference if an attacker exploits Default vs Production:**  
- In **Default**, attacker gains root with full Linux capabilities and unlimited resource use - can crash the host or pivot further.  
- In **Production**, attacker’s process has no extra privileges, can’t fork indefinitely, can’t starve CPU/RAM, and is killed/restarted if it crashes - drastically reducing blast radius.

**5. Additional hardening recommendations:**
- Run as non-root (`--user 1000:1000`).  
- Make root filesystem read-only (`--read-only`).  
- Add `--tmpfs /tmp` for ephemeral writable space only.  
- Enable Docker Content Trust (`DOCKER_CONTENT_TRUST=1`).  
- Integrate regular image scanning and signed image deployment in CI/CD.  
