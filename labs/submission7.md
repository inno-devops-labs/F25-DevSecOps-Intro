# Lab 7 Submission — Container Security Analysis


---


## Task 1 — Image Vulnerability & Configuration Analysis

### 1.1 Top 5 Critical/High Vulnerabilities

| CVE ID | Affected Package | Severity | Impact |
|--------|------------------|----------|---------|
| CVE-2023-32314 | vm2@3.9.17 | Critical | Remote Code Execution |
| CVE-2022-29256 | marsdb@0.6.11 | Critical | Code Injection |
| CVE-2022-24413 | multer@1.4.5-lts.2 | High | Denial of Service |
| CVE-2022-29229 | express-jwt@0.1.3 | High | Authorization Bypass |
| CVE-2023-32695 | socket.io@3.1.2 | High | Denial of Service |

**Total:** 30 vulnerabilities detected across dependencies.

### 1.2 Dockle Configuration Findings

**Summary Statistics:**
- **PASS:** 8 checks
- **WARN:** 2 checks  
- **FAIL:** 0 checks
- **INFO:** 1 check

**Failure Analysis:**
- **CIS-DI-0006:** No HEALTHCHECK instruction
  - **Impact:** Lack of automated health monitoring reduces system observability
  - **Remediation:** Implement HEALTHCHECK directive in Dockerfile
- **DKL-LI-0003:** Unnecessary files (.DS_Store) included
  - **Impact:** Potential information leakage and expanded attack surface
  - **Remediation:** Utilize .dockerignore and clean build context

### 1.3 Security State Assessment

**Root User Execution:** Yes, the container executes with root privileges by default, introducing privilege escalation vulnerabilities.

**Security Improvements Recommended:**
- Implement non-root user execution within container
- Activate content trust (DOCKER_CONTENT_TRUST=1)
- Eliminate unnecessary files from container image
- Incorporate HEALTHCHECK instruction
- Conduct regular vulnerability scanning procedures

---

## Task 2 — Docker Host Security Benchmarking

## 2.1 Summary Statistics

**Total Check Results:**
- **PASS:** 17 security checks
- **WARN:** Multiple configuration warnings identified  
- **FAIL:** 88 security checks
- **INFO:** Additional security observations noted

## 2.2 Analysis of Failures

### Security Failures Identified:

**Host Configuration Failures (Checks 1.1, 1.5-1.9):**
- **Security Impact:** Lack of auditing configuration prevents monitoring of security events and incident detection
- **Remediation Steps:** Implement Docker daemon and container activity auditing with comprehensive log collection

**Docker Daemon Failures (Checks 2.1, 2.8, 2.11-2.12, 2.14-2.15, 2.18):**
- **Security Impact:** Missing network isolation enables container network attacks; absent user namespaces allow privilege escalation vulnerabilities
- **Remediation Steps:** Configure user namespace remapping; implement network segmentation and TLS-based authentication

**Container Runtime Failures (Checks 5.2, 5.10-5.14, 5.25-5.28):**
- **Security Impact:** Unlimited system resources create denial-of-service risks; writable root filesystems permit unauthorized modifications
- **Remediation Steps:** Enforce strict memory, CPU, and process limits; implement read-only root filesystem configurations

### Critical Security Issues:
- Default root container execution
- Absence of resource restrictions
- Missing security controls and monitoring
- Exposure to privilege escalation and DoS attacks

### Specific Remediation Actions:
1. Activate user namespace support with proper UID/GID isolation
2. Apply comprehensive resource limitations (memory, CPU, PIDs)
3. Configure read-only root filesystem with controlled write permissions
4. Implement container healthcheck monitoringble user namespaces, apply resource limits, set read-only root FS, add healthchecks.

## Task 3 — Deployment Security Configuration Analysis

### 3.1 Configuration Comparison

| Profile | Port | Capabilities | Security Options | Memory | CPU | PIDs | Restart Policy | Status |
|---------|------|--------------|------------------|--------|-----|------|----------------|--------|
| Default | 3001 | None | None | Unlimited | Unlimited | Unlimited | none | Running |
| Hardened | 3002 | ALL dropped | no-new-privileges | 512MB | 1.0 | Unlimited | none | Running |
| Production | 3003 | ALL dropped + NET_BIND_SERVICE | no-new-privileges + seccomp | 512MB | 1.0 | 100 | on-failure:3 | Running |

**Resource Usage Analysis:**
- **Default Profile:** 102.2MiB / 14.96GiB utilized
- **Hardened Profile:** 92.37MiB / 512MB utilized
- **Production Profile:** 91.54MiB / 512MB utilized

### 3.2 Security Measures Analysis

**a) Capability Management: `--cap-drop=ALL` + `--cap-add=NET_BIND_SERVICE`**
- Minimizes attack surface through Linux capability restrictions
- Prevents privilege escalation attacks while maintaining essential port binding functionality

**b) Privilege Control: `--security-opt=no-new-privileges`**
- Blocks privilege escalation attempts through setuid binaries
- Provides protection against kernel-level security exploits

**c) Resource Limitations: `--memory=512m` + `--cpus=1.0`**
- Mitigates resource exhaustion denial-of-service attacks
- Operational consideration: Excessively restrictive limits may impact application functionality

**d) Process Management: `--pids-limit=100`**
- Defends against fork bomb attacks
- Controls maximum concurrent process execution

**e) Availability Policy: `--restart=on-failure:3`**
- Enables automatic recovery from temporary failures
- Enhanced safety compared to 'always' restart policy by preventing continuous restart loops

### 3.3 Critical Thinking

**Development Environment Recommendations:**
- Utilize Default or Hardened profiles for simplified debugging processes
- Balance security requirements with development workflow efficiency

**Production Environment Recommendations:**
- Implement Production profile for comprehensive security protection
- Leverage defense-in-depth security strategies

**Resource Limitation Benefits:**
- Prevents denial-of-service attacks through resource exhaustion
- Maintains host system stability and performance

**Attack Mitigation in Production:**
- Blocks privilege escalation vectors
- Prevents fork bomb attacks through PID restrictions
- Mitigates memory exhaustion attacks
- Controls network port binding capabilities

**Additional Security Hardening:**
- Implement AppArmor or SELinux security profiles
- Establish centralized logging infrastructure
- Configure read-only root filesystems
- Enable content trust verification
- Deploy network segmentation strategies

---

## Summary

The `juice-shop` container image demonstrates multiple critical security vulnerabilities requiring immediate remediation. Essential security enhancements include dependency library updates, systematic resource restrictions, capability management implementation, and proper runtime configuration enforcement. The deployment profile analysis reveals distinct operational trade-offs between development convenience (Default profile) and production security requirements (Production profile).