### Task 1
1. **Top 5 Critical/High Vulnerabilities**
  Here are the **Top 5 Critical/High Vulnerabilities** found in the `bkimminich/juice-shop:v19.0.0` Docker image:

| CVE ID                                         | Affected Package                  | Severity         | Impact                                      |
|------------------------------------------------|----------------------------------|------------------|---------------------------------------------|
| [SNYK-JS-MARSDB-480405](https://security.snyk.io/vuln/SNYK-JS-MARSDB-480405)        | marsdb@0.6.11                   | **Critical**     | Arbitrary Code Injection                   |
| [SNYK-JS-VM2-5537100](https://security.snyk.io/vuln/SNYK-JS-VM2-5537100)            | vm2@3.9.17                      | **Critical**     | Sandbox Bypass                             |
| [SNYK-JS-VM2-5772823](https://security.snyk.io/vuln/SNYK-JS-VM2-5772823)            | vm2@3.9.17                      | **Critical**     | Remote Code Execution (RCE)                |
| [SNYK-JS-VM2-5772825](https://security.snyk.io/vuln/SNYK-JS-VM2-5772825)            | vm2@3.9.17                      | **Critical**     | Remote Code Execution (RCE)                |
| [SNYK-JS-MULTER-10299078](https://security.snyk.io/vuln/SNYK-JS-MULTER-10299078)    | multer@1.4.5-lts.2              | **High**         | Uncaught Exception                          |

2. **Dockle Configuration Findings**
   - Nothing.. (Strange)

3. **Security Posture Assessment**
   - Does the image run as root? - No
   - What security improvements would you recommend?

---



### Task 2

Summary Statistics

Total PASS/WARN/FAIL/INFO counts
Analysis of Failures (if any)

INFO - 116
WARN - 62
PASS - 24
FAIL - 0

List failures and explain security impact
- No failures

Proposes:
 - Add healthchecks in Docker images
 - Enable user namespace support to improve security by isolating container users from host users.
 - Enable authorization for Docker client commands to restrict access and enhance security protocols.
 - Configure centralized and remote logging to ensure comprehensive monitoring and troubleshooting capabilities.
 - Enable live restore to allow containers to restore their state after a Docker daemon restart, improving reliability.
 - Disable Userland Proxy to enhance security and prevent potential unwanted network traffic.
 - Restrict containers from acquiring new privileges to minimize unnecessary security risks.


### Task 3

## Configuration Comparison

| Setting | Default | Hardened | Production |
|---------|---------|----------|------------|
| Capabilities | All enabled | Drop ALL, Add NET_BIND_SERVICE | Drop ALL, Add NET_BIND_SERVICE |
| Security Options | None | no-new-privileges | no-new-privileges |
| Memory Limit | Unlimited | 512MB | 512MB |
| CPU Limit | Unlimited | Unlimited | 1.0 CPU |
| PID Limit | Unlimited | Unlimited | 100 |
| Restart Policy | No | No | On-failure:3 |

## Security Analysis

**Capabilities:**
- Linux capabilities split root power into specific permissions
- Dropping ALL prevents privilege escalation attacks
- NET_BIND_SERVICE needed for port 80/443 binding

**no-new-privileges:**
- Blocks privilege escalation via setuid/binaries
- Prevents attackers from gaining higher privileges

**Resource Limits:**
- Prevents DoS attacks and resource exhaustion
- Stops one container from affecting others
- Too low can cause crashes

**PID Limit (100):**
- Prevents fork bomb attacks
- Limits process table exhaustion

**Restart Policy:**
- Auto-restarts on failures (max 3 tries)
- Good for availability, but can mask issues



**Which profile for DEVELOPMENT?: Default Profile**
- No security restrictions to interfere with debugging
- Full system access for testing
- Easier troubleshooting

**Which profile for PRODUCTION?: Production Profile**
- Maximum security with dropped capabilities
- Resource limits prevent DoS attacks
- PID limiting stops fork bombs
- Controlled restarts for reliability

**What real-world problem do resource limits solve?**
Prevents "noisy neighbor" issues where one container consumes all host resources and crashes other services.

**If an attacker exploits Default vs Production, what actions are blocked in Production?**
- Privilege escalation (no-new-privileges)
- Resource exhaustion attacks (memory/CPU limits)
- Fork bombs (PID limiting)
- Container escape attempts (dropped capabilities)

**What additional hardening would you add?**
- Read-only root filesystem
- User namespace remapping
- Seccomp profiles to limit system calls
- Regular vulnerability scanning
- Network policies to restrict container communication