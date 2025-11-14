# Lab 7 Submission - Container Security: Image Scanning & Deployment Hardening

## Task 1 — Image Vulnerability & Configuration Analysis

### 1.1 Top 5 Critical Vulnerabilities

| CVE ID | Affected Package | Severity | Impact |
|--------|------------------|----------|---------|
| CVE-2023-37903 | vm2@3.9.17 | Critical | Improper Neutralization of Special Elements used in an OS Command ('OS Command Injection') |
| CVE-2023-37466 | vm2@3.9.17 | Critical | Improper Control of Generation of Code ('Code Injection') |
| CVE-2023-32314 | vm2@3.9.17 | Critical | Improper Neutralization of Special Elements in Output Used by a Downstream Component ('Injection') |
| CVE-2019-10744 | lodash@2.4.2 | Critical | Improperly Controlled Modification of Object Prototype Attributes ('Prototype Pollution') |
| CVE-2015-9235 | jsonwebtoken 0.1.0 | Critical | Improper Input Validation |


### 1.2 Dockle Configuration Findings

**FATAL Issues:**
- *No FATAL issues found* - The image passed the most critical security checks

**WARN Issues:**
- *No WARN issues found* - The image configuration meets basic security standards

**INFO Issues:**
- **CIS-DI-0005**: Enable Content trust for Docker
  - export DOCKER_CONTENT_TRUST=1 before docker pull/build
  - *Security Concern*: Risk of image tampering in transit
  
- **CIS-DI-0006**: Add HEALTHCHECK instruction to the container image
  - not found HEALTHCHECK statement
  - *Security Concern*: Harder to detect unhealthy containers 
  
- **DKL-LI-0003**: Only put necessary files
  - unnecessary file : juice-shop/node_modules/micromatch/lib/.DS_Store 
  - unnecessary file : juice-shop/node_modules/extglob/lib/.DS_Store 
  - *Security Concern*: Increases attack surface and image size 

### 1.3 Security Posture Assessment

- **Runs as root:** ✅ *Yes* — major privilege escalation risk  
- **Security Hardening Recommendations:**  
  1. Create and use a **non-root user**   
  2. **Upgrade critical libraries**
  3. **Enable content trust** for verified images  
  4. **Add HEALTHCHECK** and resource limits  
  5. **Remove unnecessary files** (e.g. `.DS_Store`)  

---

## Task 2 — Docker Host Security Benchmarking

### 2.1 Summary Statistics

| Result Type | Count |
|-------------|-------|
| PASS | 22 |
| WARN | 17 |
| FAIL | 0 |
| INFO | 37 |

### 2.2 Analysis of Failures

**No FAIL results found** - The Docker host configuration meets the minimum security requirements.

**Key WARN Issues Requiring Attention:**

1. **1.1 - Separate partition for containers**
   - *Security Impact*: Containers share filesystem with host, potentially allowing resource exhaustion attacks
   - *Remediation*: Ensure a separate partition for containers has been created

2. **1.5-1.11 - Auditing configuration**
   - *Security Impact*: Lack of audit trails for Docker daemon and critical files
   - *Remediation*: Ensure auditing is configured for Docker-related files and directories

3. **2.1 - Network traffic between containers**
   - *Security Impact*: Containers can communicate freely on default bridge network
   - *Remediation*: Ensure network traffic is restricted between containers on the default bridge

4. **2.8 - User namespace support**
   - *Security Impact*: No user namespace remapping, container root = host root
   - *Remediation*: Enable user namespace support

5. **2.11 - Docker client authorization**
   - *Security Impact*: No fine-grained access control for Docker API
   - *Remediation*: Ensure that authorization for Docker client commands is enabled

6. **2.12 - Centralized logging not configured**
   - *Security Impact*: Logs may be lost or altered after compromise
   - *Remediation*: Ensure centralized and remote logging is configured

7. **2.14 - Live restore disabled**
   - *Security Impact*: Containers stop when daemon restarts → availability risk
   - *Remediation*: Ensure live restore is Enabled

8. **2.15 - Userland proxy enabled**
   - *Security Impact*: Increases attack surface and resource use
   - *Remediation*: Ensure Userland Proxy is Disabled

9. **2.18 - Containers not restricted from acquiring new privileges**
   - *Security Impact*: Processes can gain root rights via setuid binaries
   - *Remediation*: Ensure containers are restricted from acquiring new privileges


10. **4.5 - Content trust disabled**
   - *Security Impact*: Images are not verified for integrity and authenticity
   - *Remediation*: Ensure Content trust for Docker is Enabled

11. **4.6 - Missing HEALTHCHECK instructions**
   - *Security Impact*: Limited monitoring
   - *Remediation*: Ensure HEALTHCHECK instructions have been added to the container image

---

## Task 3 — Deployment Security Configuration Analysis

### 3.1 Configuration Comparison Table

| Security Feature | Default | Hardened | Production |
|------------------|---------|----------|------------|
| Capabilities Dropped | None | ALL | ALL |
| Capabilities Added | None | None | NET_BIND_SERVICE |
| Security Options | None | no-new-privileges | no-new-privileges |
| Memory Limit | Unlimited | 512MB | 512MB |
| Memory Swap Limit | Unlimited | Unlimited | 512MB |
| CPU Limit | Unlimited | 1.0 CPU | 1.0 CPU |
| PID Limit | Unlimited | Unlimited | 100 |
| Restart Policy | None | None | on-failure:3 |

### 3.2 Security Measure Analysis

#### a) `--cap-drop=ALL` and `--cap-add=NET_BIND_SERVICE`


**What are Linux capabilities?**
Linux capabilities break down root privileges into distinct units, allowing fine-grained permission control. Instead of all-or-nothing root access, containers can be granted only the specific privileges they need.

**What attack vector does dropping ALL capabilities prevent?**
Dropping ALL capabilities prevents container escape attacks, privilege escalation, and unauthorized system operations.

**Why do we need to add back NET_BIND_SERVICE?**
NET_BIND_SERVICE allows binding to privileged ports (below 1024). Web applications often need to bind to ports 80 or 443. Without this capability, the application would need to run as root or use port forwarding.

**What's the security trade-off?**
- **Gain**: Minimizes privilege exposure to a single, necessary capability.
- **Risk**: Slightly increases the attack surface (binding to low ports), but far safer than running the container as root.


#### b) `--security-opt=no-new-privileges`

**What does this flag do?**
Prevents processes within the container from gaining additional privileges through privilege escalation mechanisms.

**What type of attack does it prevent?**
- Privilege escalation via setuid binaries
- Gaining root privileges from non-root users
- Bypassing security restrictions through privilege elevation

**Are there any downsides to enabling it?**
- May break legitimate applications that require privilege changes
- Some system utilities and applications rely on setuid binaries
- Generally safe for most web applications

#### c) `--memory=512m` and `--cpus=1.0`

**What happens if a container doesn't have resource limits?**
- Single container can consume all host resources
- Denial of service for other containers and host system
- No protection against memory leaks or runaway processes

**What attack does memory limiting prevent?**
- Memory exhaustion attacks (memory bombs)
- Fork bombs that consume RAM
- Application bugs causing memory leaks
- Malicious containers consuming all available memory

**What's the risk of setting limits too low?**
- Application may crash or become unstable
- Performance degradation under load
- Need to carefully benchmark application requirements

#### d) `--pids-limit=100`

**What is a fork bomb?**
A denial of service attack where a process replicates itself exponentially to exhaust available process IDs, crashing the system. Example: `:(){ :|:& };:`

**How does PID limiting help?**
- Prevents fork bombs by limiting total processes per container
- Contains process table exhaustion to individual containers
- Provides defense against process-based DoS attacks

**How to determine the right limit?**
- Monitor normal process count during peak usage
- Consider application architecture (worker processes, threads)
- Start conservative and adjust based on monitoring

#### e) `--restart=on-failure:3`

**What does this policy do?**
Automatically restarts the container if it exits with a non-zero status code, but limits to 3 restart attempts to prevent infinite restart loops.

**When is auto-restart beneficial? When is it risky?**
- **Beneficial**: For recovering from transient failures, maintaining availability
- **Risky**: Can mask security issues, restart compromised containers, create resource exhaustion

**Compare `on-failure` vs `always`**
- **on-failure**: Only restarts on errors, allows graceful shutdowns
- **always**: Restarts regardless of exit code, can interfere with maintenance
- **on-failure** is generally safer for security-conscious deployments

### 3.3 Critical Thinking Questions

1. **Which profile for DEVELOPMENT? Why?**
   - **Default profile** - Development requires maximum flexibility for debugging and testing. Resource limits and security restrictions can interfere with development workflows, hot-reloading, and debugging tools.

2. **Which profile for PRODUCTION? Why?**
   - **Production profile** - Provides comprehensive security hardening with capability restrictions, resource limits, and process controls. The restart policy ensures high availability while the security options prevent privilege escalation attacks.

3. **What real-world problem do resource limits solve?**
   - **Noisy neighbor problem** - Prevents one misbehaving container from affecting others on the same host
   - **Resource exhaustion attacks** - Blocks DoS attacks that consume CPU, memory, or process slots
   - **Stability** - Ensures predictable performance and prevents system crashes

4. **If an attacker exploits Default vs Production, what actions are blocked in Production?**
   - **Privilege escalation**: `no-new-privileges` blocks gaining root rights via setuid binaries
   - **Container escape**: Dropped capabilities prevent kernel-level attacks
   - **Resource attacks**: Memory/CPU/PID limits contain damage
   - **Persistence**: Limited restart policy prevents automatic recovery of compromised containers
   - **Lateral movement**: Restricted capabilities limit ability to attack other containers

5. **What additional hardening would you add?**
   - **User namespace remapping**: Enable user namespace support
   - **Network policies**: Restrict container network communication
   - **Regular vulnerability scanning**: Continuous security monitoring
   - **Image signing**: Verify image integrity and provenance