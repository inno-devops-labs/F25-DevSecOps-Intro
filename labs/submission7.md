# Task 1 — Image Vulnerability & Configuration Analysis

## Top 5 Critical Vulnerabilities

### Vulnerability 1:
- **Severity**: CRITICAL
- **CVE ID**: CVE-2023-37903
- **Impact**: Improper Neutralization of Special Elements used in an OS Command ('OS Command Injection')
- **Affected package**: npm/vm2@3.9.17

### Vulnerability 2:
- **Severity**: CRITICAL
- **CVE ID**: CVE-2023-37466
- **Impact**: Improper Control of Generation of Code ('Code Injection')
- **Affected package**: npm/vm2@3.9.17

### Vulnerability 3:
- **Severity**: CRITICAL
- **CVE ID**: CVE-2023-32314
- **Impact**: - **Impact**: Improper Neutralization of Special Elements in Output Used by a Downstream Component ('Injection')
- **Affected package**: npm/vm2@3.9.17

### Vulnerability 4:
- **Severity**: CRITICAL
- **CVE ID**: CVE-2019-10744
- **Impact**: Improperly Controlled Modification of Object Prototype Attributes ('Prototype Pollution')
- **Affected package**: npm/lodash@2.4.2

### Vulnerability 5:
- **Severity**: CRITICAL
- **CVE ID**: CVE-2015-9235
- **Impact**: Improper Input Validation
- **Affected package**: npm/jsonwebtoken@0.1.0

## Dockle Configuration Findings

No FATAL and WARN issues were found.

## Security Posture Assessment

- The Juice Shop image runs as root by default.
- Recommendations:
   - Use a non-root user;
   - Implement least privilege;
   - Regular vulnerability scanning;
   - Minimal base image;
   - Multi-stage builds
   - Read-only filesystem

---

# Task 2 — Docker Host Security Benchmarking

## Summary Statistics

- **PASS**: 19
- **WARN**: 24
- **FAIL**: 0
- **INFO**: 81

## Analysis of Failures

No failures were found.

---

# Task 3 — Deployment Security Configuration Analysis

## Configuration Comparison Table

| Container       | juice-default | juice-hardened                     | juice-production                                       |
|----------------|----------------|------------------------------------|--------------------------------------------------------|
| **CapDrop**     | no value              | [ALL]                              | [ALL]                                                  |
| **SecurityOpt** | no value              | [no-new-privileges]                | [no-new-privileges, seccomp=default]                |
| **Memory**      | 3.827GiB              | 512MiB                | 512MiB                                    |
| **CPU**         | 2.21%              | 0.53%                                  | 0.45%                                                      |
| **PIDs**        | no value              | no value                                  | 100                                                    |
| **Restart**     | no             | no                                 | on-failure                                             |

## Security Measure Analysis

- **`--cap-drop=ALL` and `--cap-add=NET_BIND_SERVIC`**:
    - **What are Linux capabilities?** - Linux capabilities break down the all-or-nothing root privileges into discrete permissions. Instead of having full root access, processes can be granted specific privileges like changing file ownership, binding to privileged ports, or performing network operations.

    - **What attack vector does dropping ALL capabilities prevent?** - Dropping ALL capabilities prevents privilege escalation attacks where an attacker could use retained capabilities to perform administrative operations even if the container runs as root.

    - **Why do we need to add back `NET_BIND_SERVICE`?** - The `NET_BIND_SERVICE` capability allows binding to  ports without requiring full root privileges.
    
    - **What's the security trade-off?** - Security benefit drastically reduces attack surface by removing unnecessary privileges.
    
- **`--security-opt=no-new-privileges`**:
    - **What does this flag do?** - Prevents the container process and any child processes from gaining new privileges through setuid/setgid binaries or other privilege escalation mechanisms.

    - **What type of attack does it prevent?** - Prevents privilege escalation via SUID binaries, blocks attacks that rely on programs like `sudo`, `su`, `ping` that have elevated privileges, and mitigates against kernel exploits that require privilege escalation.

    - **What type of attack does it prevent?** - Most containerized applications don't need to change privileges during runtime. Some legacy applications or specific security tools might require privilege changes.

- **`--memory=512m` and `--cpus=1.0`**:
    - **What happens if a container doesn't have resource limits?** - Containers can consume all available host memory, causing system instability.
    - **What attack does memory limiting prevent?** - Memory exhaustion attacks (DoS).
    - **What's the risk of setting limits too low?** - Application crashes due to out-of-memory errors.

- **`--pids-limit=100`**:
    - **What is a fork bomb?** - A **fork bomb** is a denial-of-service attack where a process repeatedly replicates itself to exhaust available process slots.
    - **How does PID limiting help?** - Prevents fork bombs by limiting the total number of processes.
    - **How to determine the right limit?** - Monitor normal process count during peak usage.

- **`--restart=on-failure:3`**:
    - **What does this policy do?** - Automatically restarts the container if it exits with a non-zero status code, but only up to 3 times before giving up.
    - **When is auto-restart beneficial? When is it risky?** - Auto-restart is beneficial when handling transient failures, maintaining service availability,and recovering from occasional crashes. It is risky when masking underlying application issues, restarting compromised containers, and creating restart loops with configuration problems.
    - **Compare `on-failure` vs `always`:** 
        - `on-failure` only restarts on actual failures (non-zero exit).
        - `always` restarts regardless of exit code, can mask problems

## Critical Thinking Questions

1. **Which profile for DEVELOPMENT? Why?** - `juice-default` because faster iteration and debugging, less restrictive environment for testing, easier troubleshooting without security constraints, and full access to system resources for development tools.

2. **Which profile for PRODUCTION? Why?** - `juice-production` because defense-in-depth with multiple security layers, resource guarantees and limits, protection against container breakout, automatic recovery from failures, and minimal attack surface.

3. **What real-world problem do resource limits solve?** - prevents one container from starving others, there is predictable resource usage and billing, prevents single application from taking down entire host, and include limits impact of resource exhaustion attacks.

4. **If an attacker exploits Default vs Production, what actions are blocked in Production?** - Privilege escalation (no-new-privileges), running most root-level operations (dropped capabilities), consuming all system resources (memory/CPU/PID limits), binding to arbitrary ports (only `NET_BIND_SERVICE`), and fork bombing the host (PID limits).

5. **What additional hardening would you add?** - `--read-only` with `tmpfs` for writable directories, application-specific mandatory access control, run as different UID on host than in container, restrict network access to required ports only, use Docker secrets instead of environment variables, automated vulnerability scanning and patching, and monitor and log security-relevant events.
