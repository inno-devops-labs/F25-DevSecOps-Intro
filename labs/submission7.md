# DevSecOps Lab 7: Juice Shop Security Assessment

**Docker Image:** `bkimminich/juice-shop:v19.0.0`  
**Scanned on:** Fri Oct 24 2025

---

## 1. Top 5 Critical/High Vulnerabilities (Snyk Scan)

| Package | Vulnerability | Severity | Description / Impact | Suggested Fix |
|---------|---------------|---------|--------------------|---------------|
| vm2@3.9.17 | Remote Code Execution (RCE) | Critical | Allows executing arbitrary code within container | Upgrade to fixed version or replace library |
| marsdb@0.6.11 | Arbitrary Code Injection | Critical | Attacker can inject malicious code during runtime | No patch available; consider alternatives |
| multer@1.4.5-lts.2 | Uncaught Exception | High | Potential DoS or crash when parsing files | Upgrade to multer@2.0.2 |
| express-jwt@0.1.3 | Authorization Bypass | High | Unauthenticated access to protected routes | Upgrade to express-jwt@6.0.0 |
| socket.io@3.1.2 | Denial of Service | High | Exploitable via crafted WebSocket packets | Upgrade to socket.io@4.7.0 |

> Full list of 30 vulnerabilities detected; many have suggested upgrades.

---

## 2. Dockle Configuration Findings

| Check | Result | Security Concern |
|-------|--------|-----------------|
| DKL-LI-0001: Avoid empty password | SKIP | Passwords not detected; risk if misconfigured |
| CIS-DI-0005: Enable Content trust | INFO | Not enabled; unsigned images may be used |
| CIS-DI-0006: Add HEALTHCHECK | INFO/WARN | No healthchecks; container health cannot be monitored |
| DKL-LI-0003: Only put necessary files | WARN | `.DS_Store` files present; increases attack surface |

> **Recommendations:** Enable content trust, add HEALTHCHECK, remove unnecessary files.

---

## 3. Docker Bench for Security Summary

**Score:** 17/105  
**Total Checks:** 105  

**Highlights of WARN / FAIL:**

| Area | Check | Impact |
|------|-------|--------|
| Host Configuration | 1.1, 1.5–1.9 | Auditing not fully configured; host visibility may be reduced |
| Docker Daemon | 2.1, 2.8, 2.11–2.12, 2.14–2.15, 2.18 | Network isolation, user namespaces, authorization, logging and privilege restrictions missing |
| Container Runtime | 5.2, 5.10–5.14, 5.25–5.28 | Memory/CPU/PIDs limits missing, root FS not read-only, privileges not restricted, no healthchecks |

**Analysis:**  
The image runs as root by default. Many runtime and daemon security best practices are not fully applied, leaving containers vulnerable to privilege escalation, resource exhaustion, and network attacks.

**Recommendations:**  
- Enable user namespaces.  
- Apply memory, CPU, and PID limits.  
- Set root filesystem read-only where possible.  
- Enable container healthchecks.  
- Configure auditing and logging.

---

## 4. Deployment Profile Comparison
Three profiles tested: Default, Hardened, Production.

| Profile    | Ports | Capabilities                  | Security Options           | Memory | CPU | PIDs Limit | Restart Policy   | Status  |
|------------|-------|-------------------------------|---------------------------|--------|-----|------------|-----------------|---------|
| Default    | 3001  | None                          | None                      | Unlimited | Unlimited | Unlimited | none            | Running |
| Hardened   | 3002  | ALL dropped                   | no-new-privileges         | 512MB  | 1.0 | Unlimited | none            | Running |
| Production | 3003  | ALL dropped                   | no-new-privileges         | 512MB  | 1.0 | 100        | on-failure      | Running |

> All containers are responding with HTTP 200. Resource usage is within expected limits:
> - Default: 102.2MiB / 14.96GiB  
> - Hardened: 92.37MiB / 512MB  
> - Production: 91.54MiB / 512MB
---

## 5. Security Measure Analysis

### a) `--cap-drop=ALL` and `--cap-add=NET_BIND_SERVICE`
- Limits Linux capabilities to reduce attack surface.  
- Prevents privilege escalation while allowing binding to privileged ports.

### b) `--security-opt=no-new-privileges`
- Prevents privilege escalation via `setuid` binaries.  
- Protects against kernel exploits inside containers.

### c) `--memory` and `--cpus`
- Prevents resource exhaustion (DoS) from runaway containers.  
- Too low limits may break application functionality.

### d) `--pids-limit=100`
- Protects host from fork bombs.  
- Limits concurrent processes inside container.

### e) `--restart=on-failure:3`
- Automatically recovers from transient failures.  
- Limits restart loops to 3 attempts; safer than `always`.

---

## 6. Critical Thinking

- **Development profile:** Default or Hardened — easier debugging, basic security.  
- **Production profile:** Production (with proper seccomp) — maximum hardening and resource controls.  
- **Resource limits real-world problem:** Prevents Denial of Service and protects host stability.  
- **Attack mitigation in Production vs Default:** Production blocks privilege escalation, fork bombs, memory exhaustion, and unrestricted networking.  
- **Additional hardening recommendations:**  
  - Apply AppArmor/SELinux profiles.  
  - Enable centralized logging and monitoring.  
  - Use read-only root filesystem and restrict volume mounts.  
  - Enable Docker Content Trust for signed images.  
  - Implement network segmentation between containers.  
  - Add container HEALTHCHECKs.

---

## 7. Summary

The `juice-shop` Docker image has multiple high and critical vulnerabilities. Security can be improved with library upgrades, resource restrictions, capability drops, seccomp profiles, and better container runtime practices. Deployment profiles demonstrate the trade-offs between ease of use (Default) and hardened security (Production).
