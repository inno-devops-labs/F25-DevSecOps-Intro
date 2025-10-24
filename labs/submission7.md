# Lab 7 Submission — Container Security Analysis

**Target:** `bkimminich/juice-shop:v19.0.0`  
**Analysis Date:** October 2024

---

## Task 1 — Image Vulnerability & Configuration Analysis

### 1.1 Top 5 Critical/High Vulnerabilities

| Package | Vulnerability | Severity | Impact | Fix |
|---------|---------------|---------|--------|-----|
| vm2@3.9.17 | Remote Code Execution | Critical | Arbitrary code execution | Upgrade/replace library |
| marsdb@0.6.11 | Code Injection | Critical | Runtime code injection | No patch; use alternatives |
| multer@1.4.5-lts.2 | Uncaught Exception | High | DoS via file parsing | Upgrade to v2.0.2 |
| express-jwt@0.1.3 | Authorization Bypass | High | Unauthenticated access | Upgrade to v6.0.0 |
| socket.io@3.1.2 | Denial of Service | High | DoS via WebSocket | Upgrade to v4.7.0 |

**Total:** 30 vulnerabilities detected across dependencies.

### 1.2 Dockle Configuration Findings

| Check | Result | Security Issue |
|-------|--------|----------------|
| DKL-LI-0001: Avoid empty password | SKIP | No passwords detected |
| CIS-DI-0005: Enable Content trust | INFO | Unsigned images allowed |
| CIS-DI-0006: Add HEALTHCHECK | WARN | No health monitoring |
| DKL-LI-0003: Only put necessary files | WARN | `.DS_Store` files present |

**Recommendations:** Enable content trust, add HEALTHCHECK, remove unnecessary files.

---

## Task 2 — Docker Host Security Benchmarking

### 2.1 CIS Docker Benchmark Results

**Score:** 17/105 checks passed

| Area | Failed Checks | Issues |
|------|---------------|--------|
| Host Configuration | 1.1, 1.5-1.9 | Auditing not configured |
| Docker Daemon | 2.1, 2.8, 2.11-2.12, 2.14-2.15, 2.18 | Missing network isolation, user namespaces, logging |
| Container Runtime | 5.2, 5.10-5.14, 5.25-5.28 | No resource limits, root FS writable, excessive privileges |

**Key Issues:**
- Container runs as root by default
- Missing resource limits (memory, CPU, PIDs)
- No security restrictions or monitoring
- Vulnerable to privilege escalation and DoS attacks

**Remediation:** Enable user namespaces, apply resource limits, set read-only root FS, add healthchecks.

## Task 3 — Deployment Security Configuration Analysis

### 3.1 Configuration Comparison

| Profile | Port | Capabilities | Security Options | Memory | CPU | PIDs | Restart | Status |
|---------|------|--------------|------------------|--------|-----|------|---------|--------|
| Default | 3001 | None | None | Unlimited | Unlimited | Unlimited | none | Running |
| Hardened | 3002 | ALL dropped | no-new-privileges | 512MB | 1.0 | Unlimited | none | Running |
| Production | 3003 | ALL dropped + NET_BIND_SERVICE | no-new-privileges + seccomp | 512MB | 1.0 | 100 | on-failure:3 | Running |

**Resource Usage:**
- Default: 102.2MiB / 14.96GiB
- Hardened: 92.37MiB / 512MB  
- Production: 91.54MiB / 512MB

### 3.2 Security Measures Analysis

**a) `--cap-drop=ALL` + `--cap-add=NET_BIND_SERVICE`**
- Reduces attack surface by limiting Linux capabilities
- Prevents privilege escalation while allowing port binding

**b) `--security-opt=no-new-privileges`**
- Blocks privilege escalation via setuid binaries
- Protects against kernel exploits

**c) `--memory=512m` + `--cpus=1.0`**
- Prevents resource exhaustion DoS attacks
- Risk: Too low limits may break functionality

**d) `--pids-limit=100`**
- Protects against fork bombs
- Limits concurrent processes

**e) `--restart=on-failure:3`**
- Auto-recovery from transient failures
- Safer than `always` (prevents restart loops)

### 3.3 Critical Thinking

**Development:** Use Default or Hardened for easier debugging
**Production:** Use Production profile for maximum security
**Resource Limits:** Prevent DoS attacks and protect host stability
**Attack Mitigation:** Production blocks privilege escalation, fork bombs, memory exhaustion
**Additional Hardening:** AppArmor/SELinux, centralized logging, read-only root FS, content trust, network segmentation

---

## Summary

The `juice-shop` image contains multiple critical vulnerabilities. Security improvements require library upgrades, resource restrictions, capability management, and proper runtime configurations. Deployment profiles show clear trade-offs between usability (Default) and security (Production).