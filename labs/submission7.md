---

# Lab 7 — Container Hardening & Runtime Security (Juice Shop v19.0.0)

**Student:** Alexander Rozanov
**Branch:** `feature/lab7`
**Date:** 26 Oct 2025
**Target:** OWASP Juice Shop (`bkimminich/juice-shop:v19.0.0`)

## 1) Goal

Harden a containerized web app and compare **default** vs **hardened** vs **production-like** profiles; run image and host security checks (Docker Scout, Snyk, Dockle, Docker Bench); and document findings with remediation steps. (Per the course assignment brief) .

## 2) Tools & Evidence

All raw outputs are committed under `labs/lab7/`:

* `analysis/deployment-ps.txt` — running containers
* `analysis/deployment-comparison.txt` — functional checks, resource usage, security configs
* `scanning/scout-cves.txt` — Docker Scout CVE report
* `scanning/snyk-results.txt` — Snyk scan results
* `scanning/dockle-results.txt` — Dockle lint
* `hardening/docker-bench-results.txt` and `hardening/docker-bench-summary.txt` — Docker Bench

---

## 3) Task 1 — Image Vulnerability & Configuration Analysis

### 3.1 Docker Scout (CVE summary)

Scan target: `bkimminich/juice-shop:v19.0.0`
Overall: **9 Critical / 20 High / 24 Medium / 1 Low / 7 Unknown**, 1004 packages.
*(See `labs/lab7/scanning/scout-cves.txt` for full details.)*

**Top 5 CVEs (Critical/High):**

* **CVE-2023-37903** — `vm2 3.9.17` — **CRITICAL** — Improper Neutralization of Special Elements used in an OS Command (“OS Command Injection”)
* **CVE-2023-37466** — `vm2 3.9.17` — **CRITICAL** — Improper Control of Generation of Code (“Code Injection”)
* **CVE-2023-32314** — `vm2 3.9.17` — **CRITICAL** — Improper Neutralization of Special Elements in Output Used by a Downstream Component (“Injection”)
* **CVE-2019-10744** — `lodash 2.4.2` — **CRITICAL** — Improperly Controlled Modification of Object Prototype Attributes (“Prototype Pollution”)
* **CVE-2020-8203** — `lodash 2.4.2` — **HIGH** — Using Components with Known Vulnerabilities (Prototype Pollution)

### 3.2 Snyk scan (comparison)

*(See `labs/lab7/scanning/snyk-results.txt` for full output.)*

* **OS layer (deb/distroless):** Tested 10 dependencies — **no vulnerable paths found**.
* **Application layer (npm):** Tested 977 dependencies — **30 issues** detected (High/Critical highlights below).

**Key upgrade recommendations (selection):**

* **Upgrade** `check-dependencies@1.1.1 → 2.0.0` — fixes `braces@2.3.2` excessive resource consumption (High)
* **Upgrade** `express-jwt@0.1.3 → 6.0.0` — authorization bypass; transitive issues via old `jsonwebtoken`/`moment` (High)
* **Upgrade** `jsonwebtoken@0.4.0 → 5.0.0` — auth bypass; `jws`/`base64url` weaknesses (High)
* **Upgrade** `multer@1.4.5-lts.2 → 2.0.2` — multiple uncaught exception/memory issues (Critical/High)
* **Upgrade** `socket.io@3.1.2 → 4.7.0` — DoS and related issues in `ws`/`engine.io` (High)
* **Upgrade** `sanitize-html@1.4.2 → 1.7.1` — multiple `lodash` prototype pollution issues (High)
* **Upgrade** `pdfkit@0.11.0 → 0.12.2` — `crypto-js` weak hash usage (High)

**Issues with no direct upgrade/patch available (selection):**

* `ip@2.0.1` — SSRF (High) — no fix
* `libxmljs2@0.37.0` — Type Confusion (High) — no fix
* `lodash.set@4.3.2` — Prototype Pollution (High) — no fix
* `marsdb@0.6.11` — Arbitrary Code Injection (Critical) — no fix
* `socket.io-parser@4.0.5` — DoS (High) — fixed in 3.4.3 / 4.2.3
* `vm2@3.9.17` — Critical RCE / sandbox bypass — fixed in ≥ 3.10.0

### 3.3 Dockle configuration findings

*(See `labs/lab7/scanning/dockle-results.txt` for full output.)*

* **SKIP** — DKL-LI-0001: Avoid empty password — failed to detect `/etc/shadow`, `/etc/master.passwd` (distroless)
* **INFO** — CIS-DI-0005: Enable Docker Content Trust — set `DOCKER_CONTENT_TRUST=1` before pull/build
* **INFO** — CIS-DI-0006: Add `HEALTHCHECK` instruction — not found
* **INFO** — DKL-LI-0003: Only put necessary files — unnecessary `.DS_Store` files under `node_modules/`

**Security posture (image):**

* Distroless base; image runs as **non-root** by default (no root-user finding from Dockle).
* No `HEALTHCHECK` instruction present.
* No secrets detected in the environment at scan time.
* Recommend enabling Content Trust and pruning stray files (`.DS_Store`).

---

## 4) Task 2 — Docker Host Security Benchmarking (Docker Bench)

*(See `labs/lab7/hardening/docker-bench-results.txt` for full output.)*

**Summary:** 74 checks; **Score: 9**
**Counts:** PASS=24 / WARN=48 / FAIL=0 / INFO=100 / NOTE=7

**Notable [WARN] items and remediation:**

* **1.1** Separate partition for Docker data — dedicate `/var/lib/docker` partition; mount with `nodev,nosuid,noexec` where feasible.
* **1.5–1.11** Auditing for Docker daemon/files — add audit rules for `dockerd`, `/var/lib/docker`, service/socket, and config paths.
* **2.1** Inter-container traffic on default bridge — set `icc=false`; use user-defined networks with explicit rules.
* **2.8** User namespaces — enable `userns-remap` (e.g., `"userns-remap": "default"`) and map container UIDs to host subuids/subgids.
* **2.11** Client command authorization — enable the Docker authorization plugin (policy engine) if feasible.
* **2.12** Centralized/remote logging — ship daemon & container logs to SIEM/ELK.
* **2.14** Live restore — set `"live-restore": true` to keep containers running during daemon restarts.
* **2.15** Disable Userland Proxy — set `"userland-proxy": false` and rely on iptables-based NAT.
* **2.18** Restrict acquiring new privileges — run with `--security-opt=no-new-privileges`; enforce in platform policy/CI.
* **4.5** Content Trust — export `DOCKER_CONTENT_TRUST=1` in CI for digest pinning.
* **4.6** `HEALTHCHECK` — add to images (including Juice Shop in production builds).

> No **[FAIL]** items were reported in this run.

---

## 5) Task 3 — Deployment Security Configuration Analysis

### 5.1 Functional check

```
Default:    HTTP 200
Hardened:   HTTP 200
Production: HTTP 200
```

### 5.2 Runtime configuration comparison

| Profile    | CapDrop | CapAdd                 | SecurityOpt         | Memory  | CPU quota | PIDs | Restart        |
| ---------- | ------- | ---------------------- | ------------------- | ------- | --------- | ---- | -------------- |
| Default    | –       | –                      | –                   | 0       | 0         | –    | `no:0`         |
| Hardened   | `ALL`   | –                      | `no-new-privileges` | 512 MiB | 1.0       | –    | `no:0`         |
| Production | `ALL`   | `CAP_NET_BIND_SERVICE` | `no-new-privileges` | 512 MiB | 1.0       | 100  | `on-failure:3` |

### 5.3 Security measure analysis

**a) `--cap-drop=ALL` and `--cap-add=NET_BIND_SERVICE`**
Linux capabilities granularize root privileges. Dropping **ALL** capabilities reduces attack surface (blocks raw socket ops, module loading, device admin, etc.). `NET_BIND_SERVICE` allows binding to privileged ports (<1024) if required by fronting proxies. Trade-off: least privilege vs. needed functionality; add back only what is strictly required.

**b) `--security-opt=no-new-privileges`**
Prevents processes from gaining extra privileges (via `setuid`, file capabilities, or execve transitions), mitigating several container escape chains. Operational impact is minimal for well-behaved apps; avoid relying on setuid binaries inside the container.

**c) `--memory=512m`, `--cpus=1.0`**
Without limits, a runaway process can starve the host (“noisy neighbor”) or cause OOM kills. Limits constrain blast radius and enable fair scheduling. Too-low limits risk throttling or OOM; size via measurements and load tests.

**d) `--pids-limit=100`**
Caps the number of processes/threads to mitigate fork-bomb–style DoS and runaway worker creation. Tune per workload concurrency and thread pools; monitor `blocked`/`runnable` to adjust safely.

**e) `--restart=on-failure:3`**
Auto-restarts on non-zero exit codes up to 3 times to ride out transient faults. Prefer `on-failure` to avoid masking crash loops (`always` can restart even after manual stops). Combine with liveness checks and backoff policies.

> Note: Attempting to enforce `--security-opt=seccomp=...` with a `default` profile failed due to a missing profile path on the host. Production run proceeded **without a custom seccomp profile**; provide a valid JSON path (e.g., `/etc/docker/seccomp.json`) or rely on Docker’s built-in defaults where available.

---

## 6) Resource usage snapshot

```
NAME               CPU %     MEM USAGE / LIMIT     MEM %
juice-default      0.39%     101.5MiB / 31.24GiB   0.32%
juice-hardened     0.10%     92.35MiB / 512MiB     18.04%
juice-production   0.09%     92.73MiB / 512MiB     18.11%
```

---

## 7) Conclusion

The hardened and production-like profiles materially reduce risk: capabilities are minimized, privilege escalation is blocked, and resource abuse is constrained. Image scans highlight outdated npm dependencies (notably `vm2`, `lodash`, `jsonwebtoken`, `multer`, `socket.io`) requiring upgrades; host benchmarking surfaces daemon hardening gaps (user namespaces, live restore, content trust, logging) to address next. Enabling a valid seccomp profile is the remaining high-value control to close syscall-level attack vectors while preserving app functionality.

---

## 8) Artifacts (committed)

* `labs/lab7/analysis/deployment-ps.txt`
* `labs/lab7/analysis/deployment-comparison.txt`
* `labs/lab7/scanning/scout-cves.txt`
* `labs/lab7/scanning/snyk-results.txt`
* `labs/lab7/scanning/dockle-results.txt`
* `labs/lab7/hardening/docker-bench-results.txt`
* `labs/lab7/hardening/docker-bench-summary.txt`

---
