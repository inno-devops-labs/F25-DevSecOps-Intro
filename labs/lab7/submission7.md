## Task 1 — Image Vulnerability & Configuration Analysis

### 1.1 Overview
The target container image `bkimminich/juice-shop:v19.0.0` was analyzed using:
- **Docker Scout** – CVE and package vulnerability scanning
- **Snyk CLI** – deep dependency vulnerability comparison
- **Dockle** – configuration and best-practice assessment

| Tool | Purpose | Output File |
|------|----------|-------------|
| Docker Scout | CVE & package vulnerability scan | `labs/lab7/scanning/scout-cves.txt` |
| Snyk | Dependency comparison and remediation hints | `labs/lab7/scanning/snyk-results.txt` |
| Dockle | Configuration & Dockerfile hardening assessment | `labs/lab7/scanning/dockle-results.txt` |

---

### 1.2 Top 5 Critical / High Vulnerabilities

| # | CVE ID | Package | Severity | Description / Impact | Fixed Version |
|:-:|--------|----------|-----------|----------------------|---------------|
| 1 | **CVE-2023-37903** | `vm2 3.9.17` | **Critical (9.8)** | OS Command Injection → allows remote code execution in sandboxed contexts | Not fixed |
| 2 | **CVE-2019-10744** | `lodash 2.4.2` | **Critical (9.1)** | Prototype Pollution enabling arbitrary object modification | 4.17.12 |
| 3 | **CVE-2023-46233** | `crypto-js 3.3.0` | **Critical (9.1)** | Use of broken/risky cryptographic algorithm → may leak sensitive data | 4.2.0 |
| 4 | **CVE-2015-9235** | `jsonwebtoken 0.4.0` | **Critical (9.8)** | Improper input validation allows forged JWTs and auth bypass | 4.2.2 |
| 5 | **CVE-2021-44906** | `minimist 0.2.4` | **Critical (9.8)** | Prototype pollution / arbitrary code execution via crafted args | 1.2.6 |

> **Additional Highs (Scout + Snyk):**
> - `socket.io 3.1.2` – DoS & Uncaught Exception (CVE-2024-38355)
> - `ip 2.0.1` – SSRF vulnerability (CVE-2024-29415)
> - `multer 1.4.5-lts.2` – Memory leak and uncaught exception (CVE-2025-47935)

**Summary (from Docker Scout):**
- 61 vulnerabilities in 30 packages → **9 Critical**, **20 High**, **24 Medium**, **1 Low**, **7 Unspecified** :contentReference[oaicite:0]{index=0}
- Snyk confirmed ~30 issues, many overlapping with Scout (critical in `vm2`, `marsdb`, `jsonwebtoken`, `lodash`):contentReference[oaicite:1]{index=1}

---

### 1.3 Dockle Configuration Findings

| Level | ID | Description | Security Concern |
|:------|:--:|--------------|------------------|
| INFO | CIS-DI-0005 | Enable Content Trust (`DOCKER_CONTENT_TRUST=1`) | Without content trust, images can be tampered in transit |
| INFO | CIS-DI-0006 | No `HEALTHCHECK` instruction found | Monitoring tools can’t verify container health automatically |
| INFO | DKL-LI-0003 | Unnecessary files (e.g. `.DS_Store`) included | Increases attack surface / image size / info disclosure risk |
| SKIP | DKL-LI-0001 | Avoid empty password (test skipped) | Could not verify passwd files — manual review needed :contentReference[oaicite:2]{index=2} |

No FATAL/WARN entries were flagged in this run, but Dockle still indicates missing security best practices (e.g. lack of `HEALTHCHECK`, content trust disabled).

---

### 1.4 Security Posture Assessment

**Does the image run as root?**  
Docker Scout and the Dockerfile metadata show `--chown=65532:0`, meaning Juice Shop runs as UID 65532 (`node` user in Distroless), **not root** — good practice.

**Key Risks Observed**
1. **Outdated Node/NPM packages** with unpatched RCE and auth bypass flaws.
2. **Weak cryptography usage** (`crypto-js 3.3.0`, JWT old versions).
3. **Missing image hardening metadata** (no HEALTHCHECK, no content trust).
4. **Inclusion of development artifacts** (e.g., `.DS_Store`).

**Recommended Improvements**
- Rebuild Juice Shop with latest dependencies (`npm audit fix`, `npm update`).
- Replace deprecated libraries (`vm2`, `marsdb`, `lodash < 4.17.21`).
- Add a Dockerfile `HEALTHCHECK` for runtime monitoring.
- Enable Docker Content Trust and image signing.
- Use multi-stage builds to exclude development artifacts.
- Consider periodic CI/CD scans via Snyk or Trivy to catch new CVEs.

## Task 2 — Docker Host Security Benchmarking

### 2.1 Overview
A CIS Docker Benchmark assessment was performed using **Docker Bench for Security v1.3.4**.  
The tool checked host, daemon, and container configurations against **CIS Docker CE Benchmark v1.1.0**.

| Tool | Version | Purpose | Output File |
|------|----------|----------|-------------|
| `docker/docker-bench-security` | v1.3.4 | CIS Benchmark Compliance Audit | `labs/lab7/hardening/docker-bench-results.txt` |

---

### 2.2 Summary Statistics

| Result Type | Count | Example Checks |
|--------------|-------|----------------|
| ✅ **PASS** | 34 | Docker up to date, no privileged containers, restricted kernel capabilities |
| ⚠️ **WARN** | 31 | No memory/CPU limits, user namespaces disabled, missing AppArmor/SELinux profiles |
| ℹ️ **INFO** | 35 | Informational or skipped (e.g., missing audit files, not applicable configs) |
| 📝 **NOTE** | 10 | Optional recommendations (e.g., trusted base images, port review) |
| ❌ **FAIL** | 0 | None explicitly marked as FAIL |
| **Total Checks:** | 105 | Overall CIS Benchmark Score: **11/105** |

---

### 2.3 Analysis of Failures and Warnings

| Section | Finding | Severity | Security Impact | Recommended Remediation |
|:--------|:---------|:----------|:----------------|:------------------------|
| **1.1** | No separate partition for containers | ⚠️ WARN | Risk of data compromise if container storage fills root FS | Mount `/var/lib/docker` on a separate partition |
| **1.5** | Auditing not configured for Docker daemon | ⚠️ WARN | Activity on Docker not logged, hinders incident forensics | Enable `auditd` and add `/usr/bin/dockerd` to audit rules |
| **2.1** | Default bridge allows unrestricted inter-container traffic | ⚠️ WARN | Containers can laterally move or sniff traffic | Use custom user-defined bridge networks |
| **2.8** | User namespace support disabled | ⚠️ WARN | Containers share host UID/GID mapping → privilege escalation risk | Enable with `--userns-remap=default` |
| **2.11–2.15** | Missing authorization, remote logging, and live restore | ⚠️ WARN | Potential for daemon tampering and limited forensic trace | Configure `authorization-plugins` and centralized log forwarding |
| **3.15** | Wrong ownership for `/var/run/docker.sock` | ⚠️ WARN | Docker socket may allow unauthorized access to Docker API | Change owner to `root:docker` and permissions to `660` |
| **4.1** | Container runs as root (`backend-db-1`) | ⚠️ WARN | Elevated privileges → full container breakout possible | Define non-root `USER` in Dockerfile |
| **4.5–4.6** | Content Trust disabled and no HEALTHCHECK | ⚠️ WARN | Images unverifiable and health unmonitored | Enable Docker Content Trust and add `HEALTHCHECK` in Dockerfile |
| **5.1–5.2** | AppArmor and SELinux not applied | ⚠️ WARN | No mandatory access control → process confinement lost | Apply `--security-opt apparmor:docker-default` or enable SELinux |
| **5.10–5.14** | No memory, CPU, or restart limits | ⚠️ WARN | Resource DoS possible, containers restart indefinitely | Use `--memory`, `--cpus`, and `--restart=on-failure:3` |
| **5.12–5.13** | Root filesystem writable and binds to `0.0.0.0` | ⚠️ WARN | Host file overwrite and wide network exposure | Mount FS as read-only; restrict binding via `--publish 127.0.0.1:PORT` |
| **5.25** | Containers not restricted from new privileges | ⚠️ WARN | Allows privilege escalation via SUID binaries | Add `--security-opt no-new-privileges` |
| **5.28** | PID cgroup limit not set | ⚠️ WARN | Risk of fork bomb or runaway process | Use `--pids-limit=100` |

---

### 2.4 Security Impact Summary

**Top Concerns:**
1. Containers running as **root** and without resource limits.
2. **User namespaces** not enabled, exposing host identity mappings.
3. **Lack of auditing and remote logging**, limiting accountability.
4. **Unrestricted container networking**, allowing lateral traffic.
5. **No MAC (AppArmor/SELinux) enforcement**, reducing isolation.

These collectively increase the risk of **privilege escalation, DoS attacks, and container escapes** in multi-tenant environments.

---

### 2.5 Recommended Remediation Steps

| Category | Hardening Action | Command / Config Example |
|-----------|------------------|--------------------------|
| **Namespaces** | Enable user remapping | `/etc/docker/daemon.json`: `{ "userns-remap": "default" }` |
| **Audit & Logging** | Enable audit rules for Docker | `auditctl -w /usr/bin/dockerd -p wa -k docker` |
| **Networking** | Isolate containers | Use user-defined bridge networks instead of default |
| **Access Control** | Restrict socket permissions | `chown root:docker /var/run/docker.sock && chmod 660 /var/run/docker.sock` |
| **Runtime Security** | Enforce AppArmor or SELinux | `--security-opt apparmor:docker-default` |
| **Resource Limits** | Apply CPU, memory, PID limits | `--memory=512m --cpus=1.0 --pids-limit=100` |
| **Monitoring** | Add health checks | `HEALTHCHECK CMD curl -f http://localhost:3000/health || exit 1` |
| **Trust & Integrity** | Enable Docker Content Trust | `export DOCKER_CONTENT_TRUST=1` |


## Task 3 — Deployment Security Configuration Analysis

### 3.1 Results Snapshot

All profiles responded successfully:

- **Default:** HTTP 200
- **Hardened:** HTTP 200
- **Production:** HTTP 200  :contentReference[oaicite:0]{index=0}

Resource usage (one-shot `docker stats`):

- Default: ~101 MiB
- Hardened: ~95 MiB (**512 MiB limit**)
- Production: ~92 MiB (**512 MiB limit**)  :contentReference[oaicite:1]{index=1}

### 3.2 Configuration Comparison (from `docker inspect`)

| Setting | Default | Hardened | Production |
|---|---|---|---|
| Capabilities | *(none dropped)* | `CapDrop=ALL` | `CapDrop=ALL` |
| Security options | – | `no-new-privileges` | `no-new-privileges` |
| Memory limit | **Unlimited** | **512 MiB** | **512 MiB** |
| CPU limit | **Unlimited** | **Unlimited** | **Unlimited** |
| PIDs limit | – | – | **100** |
| Restart policy | `no` | `no` | `on-failure` |  
_Source: `analysis/deployment-comparison.txt` (functionality, stats, and inspect excerpts)._  :contentReference[oaicite:2]{index=2}

> Note: The lab’s baseline command set CPU limits, but this run shows **no CPU quota** applied (all three report `CPU: 0`). Consider re-running Production with `--cpus=1.0` if you want CPU enforcement.

---

### 3.3 Security Measure Analysis

**a) `--cap-drop=ALL` and `--cap-add=NET_BIND_SERVICE`**
- *Linux capabilities* split root’s powers into granular privileges. Dropping **ALL** eliminates broad kernel-level actions (e.g., module load, raw sockets), shrinking attack surface.
- Add back **`NET_BIND_SERVICE`** only if binding to ports `<1024` is required. On port **3000** it’s not needed; keeping it demonstrates “least privilege + allow only what you need.”
- **Trade-off:** Some ops that require specific caps will fail until explicitly added.

**b) `--security-opt=no-new-privileges`**
- Prevents processes from gaining new privileges (e.g., via setuid binaries or `filecap`s), mitigating **privilege escalation** paths.
- Side-effect: legacy tooling relying on setuid may break (rare for app containers).

**c) `--memory=512m` and `--cpus=1.0`**
- Without limits, a single container can starve the host (**resource DoS**).
- Memory cap avoids OOMing the node; CPU cap ensures fair scheduling.
- **Risk if too low:** OOM kills and timeouts; tune via load testing.
- *In this run:* memory limits are active for Hardened/Production; **CPU caps were not set** (see table).

**d) `--pids-limit=100`**
- Caps the total processes/threads, preventing **fork bombs** or runaway concurrency.
- Choose a value based on real concurrency + headroom observed under load.

**e) `--restart=on-failure:3`**
- Restarts the container up to 3 times on crash, improving resilience while avoiding infinite crash loops.
- `on-failure` (bounded) is safer than `always` (restarts even after manual stops).

**Additional hardening commonly used**
- `--read-only` root FS, plus `tmpfs /tmp` and explicit volumes for writable paths.
- AppArmor/SELinux profiles; custom seccomp profile; bind to `127.0.0.1` behind a reverse proxy.

---

### 3.4 Critical Thinking

1) **Which profile for DEVELOPMENT? Why?**  
   **Default.** Minimal friction and full functionality; useful for rapid iteration.

2) **Which profile for PRODUCTION? Why?**  
   **Production.** Enforces least privilege (`cap-drop=ALL`, `no-new-privileges`), cgroup limits, PID cap, and restart policy; reduces blast radius and improves resilience.

3) **What real-world problem do resource limits solve?**  
   Contain **noisy neighbor / DoS** risks so one service can’t starve others (memory or CPU).

4) **If an attacker exploits Default vs Production, what’s blocked in Production?**
- Gaining extra privileges (blocked by **NNP**).
- Spawning unbounded processes (blocked by **PIDs limit**).
- CPU/memory exhaustion of the node (blocked by **cgroup limits**).
- Many kernel-level actions (blocked by **capability drops**).
- (If added) writing to root FS (blocked by **read-only**).

5) **What additional hardening would you add?**
- Explicit **non-root `USER`** (if image didn’t already), read-only root FS with minimal writable mounts, **AppArmor/SELinux**, **custom seccomp** tailored to the app, `--cpus=1.0`, stricter `ulimit` (e.g., `nofile`), and network isolation on a user-defined bridge with ingress restricted.
