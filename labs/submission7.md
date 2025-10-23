# Lab 7 Submission — Container Security: Image Scanning & Deployment Hardening

This report documents the results of the Lab 7 exercises: image vulnerability scanning, Docker host benchmarking against the CIS Docker Benchmark, and deployment security configuration comparison. All commands were executed exactly as listed in `labs/lab7.md`. Evidence and raw outputs are included in `labs/lab7/` (subfolders `scanning`, `hardening`, and `analysis`).

---

## Executive summary

- Target image: `bkimminich/juice-shop:v19.0.0` (172 MB, 1004 packages)
- Docker Scout findings: 61 vulnerabilities total (9 Critical, 20 High, 24 Medium, 1 Low, 7 unspecified)
- Snyk container scan: 30 vulnerable paths (Critical multer RCE, express-jwt auth bypass, vm2 sandbox escapes, lodash prototype pollution)
- Dockle: configuration best-practice warnings (no HEALTHCHECK, content trust not enabled, unnecessary files in image)
- Docker Bench: host-level WARNs around auditing, user namespaces, content trust, resource limits, and container privilege restrictions (Score: 17 / 105 checks)
- Deployment comparison: Baseline and Hardened profiles launched successfully. Production profile could not be created with `--security-opt=seccomp=default` on this host (seccomp profile not available) — comparison focuses on Default vs Hardened, and notes the production profile error.

All raw outputs have been saved in `labs/lab7/`:
- `labs/lab7/scanning/scout-cves.txt` (Docker Scout CVE output)
- `labs/lab7/scanning/snyk-results.txt` (Snyk container scan output)
- `labs/lab7/scanning/dockle-results.txt` (Dockle configuration scan)
- `labs/lab7/hardening/docker-bench-results.txt` (Docker Bench CIS report)
- `labs/lab7/analysis/deployment-comparison.txt` (deployment tests and inspect outputs)

---

## Task 1 — Image Vulnerability & Configuration Analysis

Command run (evidence):

```
docker pull bkimminich/juice-shop:v19.0.0
docker scout cves bkimminich/juice-shop:v19.0.0 | tee scanning/scout-cves.txt
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \ 
  goodwithtech/dockle:latest bkimminich/juice-shop:v19.0.0 | tee scanning/dockle-results.txt
docker run --rm -e SNYK_TOKEN -v /var/run/docker.sock:/var/run/docker.sock \
  snyk/snyk:docker snyk test --docker bkimminich/juice-shop:v19.0.0 \
  --severity-threshold=high | tee scanning/snyk-results.txt
```

Summary of findings (Docker Scout):

- Total vulnerabilities: 61
  - Critical: 9
  - High: 20
  - Medium: 24
  - Low: 1
  - Unspecified: 7

Top critical/high issues observed (examples from `scout-cves.txt`):

1. vm2 3.9.17 — multiple CRITICAL code-injection CVEs (CVE-2023-37903, CVE-2023-37466, CVE-2023-32314). CVSS 9.8 — remote code/command injection risk.
2. lodash 2.4.2 — CRITICAL prototype pollution (CVE-2019-10744) and several HIGH CVEs. Fixed versions exist (>=4.17.12).
3. jsonwebtoken 0.1.0/0.4.0 — CRITICAL/High issues; upgrade to modern maintained version (>=9.0.0) recommended.
4. minimist 0.2.4 — CRITICAL (CVE-2021-44906). Fixed in 1.2.6.
5. crypto-js / tar-fs / multer — HIGH/CRITICAL vulnerabilities (crypto algorithm issues, path traversal, memory issues).

Why these matter:
- Several of the top vulnerabilities are remote code execution or prototype pollution issues in widely-used JS libraries — exploitable via crafted input and potentially leading to full compromise of the application container.

Snyk container scan (`snyk-results.txt`):

- Tested 977 npm dependencies and 10 Debian base components; 30 issues flagged across application dependencies (severity threshold ≥ High).
- Critical / High highlights:
  - `multer@1.4.5-lts.2` — Critical RCE/uncaught exception vulnerabilities.
  - `express-jwt@0.1.3` / `jsonwebtoken@0.4.0` — High severity auth bypass and forgeable tokens.
  - `socket.io@3.1.2` / `engine.io@4.1.2` — High severity DoS vectors.
  - `lodash@2.4.2` — Multiple prototype pollution issues.
  - `vm2@3.9.17` — Critical sandbox escapes (aligns with Scout findings).

Dockle configuration findings (`dockle-results.txt`):

- DKL-LI-0001: SKIP - (no /etc/shadow detected in image)
- CIS-DI-0005: INFO - Content trust not enabled. Recommend enabling DOCKER_CONTENT_TRUST for image pulls.
- CIS-DI-0006: INFO - No `HEALTHCHECK` in image. Recommend adding HEALTHCHECK for runtime health monitoring.
- DKL-LI-0003: INFO - Unnecessary files found (e.g., `.DS_Store` files under node_modules) — remove in image build.

Recommendations (Task 1):

1. Rebuild the image using an updated base and pinned, patched dependencies. For Node.js, run `npm audit fix` and update packages then rebuild a minimal image.
2. Replace or update vulnerable packages explicitly (vm2, lodash, jsonwebtoken, minimist, crypto-js, multer, tar-fs). If no fixed version exists, consider mitigation (isolate, runtime WAF, restrict inputs) or upstream patching.
3. Add a `HEALTHCHECK` instruction to the Dockerfile. Example:

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s CMD curl -f http://localhost:3000/ || exit 1
```

4. Enable Docker Content Trust for CI and production pulls (set `DOCKER_CONTENT_TRUST=1` in CI and production environments).
5. Remove unnecessary files and reduce attack surface (strip dev files, .DS_Store, unused modules).

- Top 5 Critical/High vulnerabilities (concise remediation):

- `multer@1.4.5-lts.2` Critical RCE (SNYK-JS-MULTER-10299078): upgrade to >=2.0.2 or replace upload handler.
- `express-jwt@0.1.3` auth bypass (SNYK-JS-EXPRESSJWT-575022): upgrade to >=6.0.0 and rotate secrets; consider Passport/JWT modern libs.
- `jsonwebtoken@0.4.0` / `jws@0.2.6` token forgery (npm:jws:20160726): upgrade to >=9.0.0; enforce signature verification.
- `vm2@3.9.17` sandbox escapes (SNYK-JS-VM2-5537100/5772823): remove vm2, upgrade to >=3.9.18+, or isolate chat-bot feature.
- `lodash@2.4.2` prototype pollution (SNYK-JS-LODASH-73638 et al.): upgrade to >=4.17.21 and audit transitive deps.

Evidence snippets are included in `labs/lab7/scanning/scout-cves.txt`.

---

## Task 2 — Docker Host Security Benchmarking (CIS Docker Benchmark)

Command run (evidence):

```
docker run --rm --net host --pid host --userns host --cap-add audit_control \
  -e DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST \
  -v /var/lib:/var/lib:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /usr/lib/systemd:/usr/lib/systemd:ro \
  -v /etc:/etc:ro --label docker_bench_security \
  docker/docker-bench-security | tee hardening/docker-bench-results.txt
```

Summary (high-level):

- Total checks: 105 — Score reported: 17 (many WARNs)
- Notable WARNs/FAILs:
  - 1.1 Ensure a separate partition for containers (WARN)
  - 1.5–1.10 Auditing for Docker daemon/files (WARN) — audit subsystem not configured for many Docker files
  - 2.8 User namespace support not enabled (WARN)
  - 2.11 Authorization for Docker client commands not enabled (WARN)
  - 2.12 Centralized and remote logging not configured (WARN)
  - 4.1 Containers running as root (several WARNs)
  - 4.5 Content trust not enabled (WARN)
  - 4.6 HEALTHCHECK missing across multiple images (WARN)
  - 5.10–5.12 Resource limits and read-only root filesystem not enforced for some containers (WARN)
  - 5.31 Docker socket is mounted in a container (WARN) — exposes host to risk

Analysis of failures / security impact:

- Missing auditing (auditd) means security events related to Docker may not be logged or monitored; forensic and compliance gaps.
- User namespaces not enabled: containers map directly to host UIDs, increasing risk if container breakout occurs.
- Running containers as root increases blast radius for container escapes.
- Docker socket mounted inside a container is a critical misconfiguration — any process in that container can control Docker and the host.

Recommended remediations (host):

1. Enable and configure auditing for Docker binaries and key directories (auditd rules for /var/lib/docker, /etc/docker, docker.service, docker.socket).
2. Enable user namespace remapping (configure `userns-remap` in daemon.json) where appropriate.
3. Avoid mounting the Docker socket into containers; use API proxies with RBAC or a privileged CI runner with least privilege.
4. Enforce image HEALTHCHECK and Content Trust for production pulls.
5. Configure resource limits and set read-only root filesystem for deployed containers.

Evidence file: `labs/lab7/hardening/docker-bench-results.txt` (full output attached in workspace).

---

## Task 3 — Deployment Security Configuration Analysis

Commands run (evidence):

```
# Profile 1: Default (baseline)
docker run -d --name juice-default -p 3001:3000 bkimminich/juice-shop:v19.0.0

# Profile 2: Hardened
docker run -d --name juice-hardened -p 3002:3000 \
  --cap-drop=ALL --security-opt=no-new-privileges --memory=512m --cpus=1.0 \
  bkimminich/juice-shop:v19.0.0

# Profile 3: Production (maximum hardening) — attempted but failed on this host:
docker run -d --name juice-production -p 3003:3000 \
  --cap-drop=ALL --cap-add=NET_BIND_SERVICE --security-opt=no-new-privileges \
  --security-opt=seccomp=default --memory=512m --memory-swap=512m --cpus=1.0 \
  --pids-limit=100 --restart=on-failure:3 bkimminich/juice-shop:v19.0.0

# After startup: sleep 15; docker ps -a --filter name=juice-
# Functionality and resource checks saved to analysis/deployment-comparison.txt
```

Outcome and verification (from `analysis/deployment-comparison.txt`):

- Functionality test HTTP status:
  - Default: HTTP 200
  - Hardened: HTTP 200
  - Production: could not be started due to seccomp profile error on host (`open default: no such file or directory`) — production container was not available for live testing on this host.

- Resource and inspect summary (selected fields):

| Container       | CapDrop | SecurityOpt           | Memory (bytes) | CPUQuota | PIDs | Restart |
|-----------------|---------|-----------------------|----------------|----------|------|---------|
| juice-default   | -       | -                     | 0              | 0        | -    | no      |
| juice-hardened  | [ALL]   | [no-new-privileges]   | 536870912      | 0        | -    | no      |
| juice-production| (failed to start - seccomp profile missing on host)                                    |

Note: memory is shown as `536870912` bytes for the hardened container (512 MB). CPU quota reported as 0 for these runs (host-specific details); limits were applied via `--cpus=1.0` which maps to CFS settings on the host.

Answers to specific lab questions:

a) `--cap-drop=ALL` and `--cap-add=NET_BIND_SERVICE` — what and why?

- Linux capabilities are fine-grained privileges that allow processes to perform privileged actions without granting full root. Dropping all capabilities removes many default privileges, reducing attack surface. `NET_BIND_SERVICE` allows binding to low-numbered ports (e.g., 80/443) without full root. The trade-off: you reduce possible privilege escalation vectors but must re-add only capabilities strictly required for the service.

b) `--security-opt=no-new-privileges` — what it does and what it prevents

- This prevents processes in the container (or child processes) from gaining new privileges via `setuid` binaries or other escalation paths. It mitigates common privilege escalation techniques and helps contain exploits. Downside: some legitimate workflows that require privilege escalation (rare) may break.

c) `--memory=512m` and `--cpus=1.0` — why resource limits matter

- Without limits, a container can exhaust host memory or CPU, affecting other workloads (denial-of-service by resource starvation). Memory limits prevent out-of-control OOM situations and limit blast radius. Setting limits too low may cause legitimate processes to be killed or throttled — choose values based on load testing and monitoring.

d) `--pids-limit=100` — fork bombs and mitigation

- A fork bomb exhausts available process slots, causing host instability. PID limiting restricts the max processes a container can spawn, mitigating fork bombs. Choose limits based on application process model and stress testing.

e) `--restart=on-failure:3` — behavior and trade-offs

- Auto-restart on failure helps self-healing for transient failures. `on-failure:3` retries up to 3 times. `always` restarts regardless of exit status (can hide crash loops). Use `on-failure` with restart limits in production; combine with health checks and alerting.

Which profile for DEVELOPMENT vs PRODUCTION?

- Development: `Default` or a minimally hardened profile (developer convenience). Keep resource limits sane but allow easier debugging.
- Production: `Hardened` + additional controls (non-root user, read-only rootfs, strict seccomp profile, capability drops, PID limits, healthchecks, resource limits, centralized logging). The attempted `Production` profile on this host failed due to missing seccomp profile; in production, ensure the environment has the intended seccomp profile available.

Additional hardening suggestions:

1. Run the container as a non-root user (set `USER` in Dockerfile).
2. Set `--read-only` and mount writable volumes only where needed.
3. Use a custom, restrictive seccomp profile file and provide it explicitly if `default` is not available.
4. Add `HEALTHCHECK` and expose only required ports.
5. Use an image built with minimal base (scratch or distroless) and updated dependencies.

---

## Evidence and artifacts

- `labs/lab7/scanning/scout-cves.txt` — full Docker Scout output (61 vulns; top CVEs listed in Task 1 section).
- `labs/lab7/scanning/dockle-results.txt` — Dockle output (HEALTHCHECK missing, content trust warning, unnecessary files).
- `labs/lab7/scanning/snyk-results.txt` — Snyk output (30 issues with upgrade guidance and unpatched vulns).
- `labs/lab7/hardening/docker-bench-results.txt` — full Docker Bench output (105 checks, Score 17; many WARNs documented above).
- `labs/lab7/analysis/deployment-comparison.txt` — deployment verification, HTTP codes, container inspect outputs.

All of the above files are included in the repository under `labs/lab7/`.
