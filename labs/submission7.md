# Lab 7 — Container Security: Image Scanning & Deployment Hardening

---

## Task 1 — Image Vulnerability & Configuration Analysis

### Top 5 Critical/High Vulnerabilities

| CVE ID        | Affected Package | Severity  | Impact                                                                 |
|---------------|-----------------|----------|------------------------------------------------------------------------|
| CVE-2023-37903 | vm2 3.9.17      | Critical | OS Command Injection, allows execution of commands without authorization |
| CVE-2023-37466 | vm2 3.9.17      | Critical | Code Injection, enables remote execution of arbitrary code            |
| CVE-2023-32314 | vm2 3.9.17      | Critical | Injection vulnerability, may compromise system integrity               |
| CVE-2019-10744 | lodash 2.4.2    | Critical | Prototype Pollution, can modify internal objects and application behavior |
| CVE-2023-46233 | crypto-js 3.3.0 | Critical | Weak cryptographic algorithm, risks confidentiality of data           |

Total vulnerabilities: 61 (9 Critical, 20 High, 24 Medium, 1 Low, 7 Unspecified)

### Dockle Configuration Findings

| Issue                 | Severity | Security Concern                                                    |
|-----------------------|---------|---------------------------------------------------------------------|
| Running as root        | FATAL   | Container running as root may allow privilege escalation            |
| Exposed secrets in ENV | WARN    | Environment variables may leak sensitive information               |
| Missing health check   | WARN    | Lack of health checks makes it harder to detect container failures |
| File permission issues | WARN    | Improper file permissions can expose sensitive files               |

### Security Posture Assessment

- Does the image run as root? Yes  
- Recommended security improvements: 
  1. Use a non-root user inside the container  
  2. Update vulnerable packages  
  3. Add health checks  
  4. Minimize file permissions  
  5. Avoid storing secrets in environment variables

---

## Task 2 — Docker Host Security Benchmarking

### 1. Summary Statistics

| Result | Count |
|--------|-------|
| PASS   | 41    |
| WARN   | 50    |
| FAIL   | 0     |
| INFO   | 14    |

### 2. Analysis of Failures

No explicit FAIL results were reported.  

#### WARN Findings with Security Impact and Remediation

1. **Containers running as root** (nginx, renderer)  
   - **Impact:** Increases risk of privilege escalation if the container is compromised.  
   - **Remediation:** Create and use a non-root user inside containers.

2. **No Healthcheck instructions in many images**  
   - **Impact:** Lack of automated monitoring for container health; failures may go undetected.  
   - **Remediation:** Add `HEALTHCHECK` instructions to Dockerfiles for all containers.

3. **Privileged containers in use** (terminal)  
   - **Impact:** Containers with full host privileges can compromise the host system.  
   - **Remediation:** Avoid privileged mode; restrict capabilities using `--cap-drop` and `--security-opt`.

4. **Containers without memory/CPU limits** (nginx, renderer, terminal)  
   - **Impact:** Can lead to resource exhaustion on the host.  
   - **Remediation:** Set `--memory` and `--cpus` limits in container runtime.

5. **Containers with root filesystem mounted read/write** (nginx, renderer, terminal)  
   - **Impact:** Increases risk of tampering with container filesystem.  
   - **Remediation:** Mount root filesystem as read-only with `--read-only`.

6. **Docker socket mounted in container** (terminal)  
   - **Impact:** Provides full control over Docker daemon to the container.  
   - **Remediation:** Avoid mounting `/var/run/docker.sock` unless strictly necessary.

7. **No PIDs cgroup limits** (nginx, renderer, terminal)  
   - **Impact:** Containers can fork unlimited processes, risking host stability.  
   - **Remediation:** Set `--pids-limit` for all containers.

8. **Privileges not restricted** (nginx, renderer, terminal)  
   - **Impact:** Containers can acquire additional capabilities.  
   - **Remediation:** Apply `--security-opt=no-new-privileges` for containers.

9. **Docker Content Trust not enabled**  
   - **Impact:** Increases risk of running unverified or malicious images.  
   - **Remediation:** Enable Docker Content Trust with `DOCKER_CONTENT_TRUST=1`.

10. **User namespace support not enabled**  
    - **Impact:** Containers share host UID/GID, increasing attack surface.  
    - **Remediation:** Enable user namespaces in Docker daemon configuration.

11. **Live restore not enabled**  
    - **Impact:** Containers may stop during Docker daemon restarts.  
    - **Remediation:** Enable `live-restore` in `daemon.json`.

12. **Userland proxy enabled**  
    - **Impact:** May expose unnecessary network attack surface.  
    - **Remediation:** Disable userland proxy in Docker daemon configuration.

13. **Containers can acquire new privileges**  
    - **Impact:** May escalate privileges inside container.  
    - **Remediation:** Use `--security-opt=no-new-privileges` and drop unnecessary capabilities.

14. **SELinux security options not set** (nginx, renderer)  
    - **Impact:** Lack of mandatory access control reduces isolation.  
    - **Remediation:** Enable SELinux and define appropriate security policies.

15. **Memory and CPU limits not enforced**  
    - **Impact:** Resource starvation risk for host and other containers.  
    - **Remediation:** Apply proper resource constraints.

16. **MaximumRetryCount for restart policy not set** (nginx, renderer, terminal)  
    - **Impact:** Containers may restart indefinitely without limits.  
    - **Remediation:** Set `--restart=on-failure:5`.

17. **Container health not checked at runtime** (nginx, renderer)  
    - **Impact:** Runtime failures may remain undetected.  
    - **Remediation:** Use `HEALTHCHECK` to monitor container status.

18. **Docker socket shared with container** (terminal)  
    - **Impact:** Full host control risk.  
    - **Remediation:** Avoid exposing Docker socket.

**Overall Recommendation:** Apply non-root users, resource limits, capability restrictions, health checks, Content Trust, and SELinux/AppArmor protections to improve Docker security posture.

---

## Task 3 — Deployment Security Configuration Analysis

### 1. Configuration Comparison Table

| Container        | Capabilities                       | Security Options                    | Memory Limit | CPU Quota | PIDs Limit | Restart Policy |
|------------------|-----------------------------------|------------------------------------|--------------|-----------|------------|----------------|
| juice-default     | <none>                            | <none>                             | unlimited    | 0         | unlimited  | no             |
| juice-hardened    | ALL dropped                        | no-new-privileges                  | 512 MB       | 0         | unlimited  | no             |
| juice-production  | ALL dropped, NET_BIND_SERVICE added| no-new-privileges, seccomp=default| 512 MB       | 0         | 100        | on-failure:3   |

### 2. Security Measure Analysis

**a) --cap-drop=ALL and --cap-add=NET_BIND_SERVICE**  
- Linux capabilities: fine-grained permissions allowing processes to perform privileged operations without full root.  
- Dropping ALL capabilities: prevents dangerous operations like mounting filesystems, changing network config, or loading kernel modules. Mitigates privilege escalation.  
- Adding NET_BIND_SERVICE: allows binding to ports <1024; trade-off: adds minimal necessary privilege.  

**b) --security-opt=no-new-privileges**  
- Prevents processes in container from gaining new privileges (e.g., via setuid binaries).  
- Mitigates privilege escalation attacks.  
- Downside: some legitimate applications may fail if they require privilege escalation.  

**c) --memory=512m and --cpus=1.0**  
- Prevents resource exhaustion attacks (DoS via memory/CPU).  
- Risk if limits too low: legitimate workloads may fail or be throttled.  

**d) --pids-limit=100**  
- Fork bomb: process creating processes recursively to exhaust system PIDs.  
- PID limiting prevents a container from exhausting host PID namespace.  
- Right limit: based on expected workload; 100 is safe for small web apps.  

**e) --restart=on-failure:3**  
- Automatically restarts container up to 3 times on failure.  
- Benefits: improves availability.  
- Risks: may mask persistent errors.  
- Comparison: `always` restarts regardless of exit code; `on-failure` only restarts on failure, safer for production.  

### 3. Critical Thinking Questions

**Development profile:**  
- Recommended: juice-default or juice-hardened  
- Reason: easier debugging, fewer restrictions, quick iteration. Hardened safer if testing security features.  

**Production profile:**  
- Recommended: juice-production  
- Reason: maximum hardening, resource limits, privilege reduction, seccomp enforcement, PID limits, auto-restart.  

**Real-world problem solved by resource limits:**  
- Prevents a single container from consuming all host resources, protecting other services from DoS.  

**Exploitation differences (Default vs Production):**  
- Default: attacker could escalate privileges, fork bomb the host, abuse unlimited resources.  
- Production: dangerous capabilities removed, PID/memory limits prevent host impact, no-new-privileges prevents escalation.  

**Additional hardening suggestions:**  
- Use non-root user (`USER node`)  
- Enable read-only filesystem (`--read-only`)  
- Enable logging/monitoring  
- Regular CVE scans of images  
- Network segmentation (`--network isolation`)  
