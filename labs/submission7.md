# Lab 7 — Container Security: Image Scanning & Deployment Hardening

## Tasks

### Task 1 — Image Vulnerability & Configuration Analysis (3 pts)

#### Top 5 Critical/High Vulnerabilities

  1. **CVE-2023-37903** - vm2 3.9.17
     - **Affected Package**: vm2@3.9.17
     - **Severity**: CRITICAL, CVSS 9.8
     - **Impact**: Allows remote code execution
  
  2. **CVE-2023-37466** - vm2 3.9.17
     - **Affected Package**: vm2@3.9.17
     - **Severity**: CRITICAL, CVSS 9.8
     - **Impact**: Allows remote code execution
  
  3. **CVE-2023-32314** - vm2 3.9.17
     - **Affected Package**: vm2@3.9.17
     - **Severity**: CRITICAL, CVSS 9.8
     - **Impact**: Allows injection attacks
  
  4. **CVE-2019-10744** - lodash 2.4.2
     - **Affected Package**: lodash@2.4.2
     - **Severity**: CRITICAL, CVSS 9.1
     - **Impact**: Allows modification of object prototypes
  
  5. **CVE-2023-46233** - crypto-js 3.3.0
     - **Affected Package**: crypto-js@3.3.0
     - **Severity**: CRITICAL, CVSS 9.1
     - **Impact**: Weak encryption implementation can result in data compromise

#### Dockle Configuration Findings ####
```
  SKIP	- DKL-LI-0001: Avoid empty password
	* failed to detect etc/shadow,etc/master.passwd
  INFO	- CIS-DI-0005: Enable Content trust for Docker
	* export DOCKER_CONTENT_TRUST=1 before docker pull/build
  INFO	- CIS-DI-0006: Add HEALTHCHECK instruction to the container image
	* not found HEALTHCHECK statement
  INFO	- DKL-LI-0003: Only put necessary files
	* unnecessary file : juice-shop/node_modules/extglob/lib/.DS_Store 
	* unnecessary file : juice-shop/node_modules/micromatch/lib/.DS_Store 
```

- **CIS-DI-0005** - Enable Content trust for Docker
  Lack of content trust may result in tampered images
- **CIS-DI-0006** - Add HEALTHCHECK instruction to the container image
  Without healthcheck, container may die or work improperly unnoticed (until everything else breaks)
- **DKL-LI-0003** - Only put necessary files.
  Unnecessary files increase attack surface

#### Security Posture Assessment

- The image runs as root by default, which is security risk. Creating non-root user recommended.
- Update vulnerable packages to newer versions.
- Enable content trust in Docker.
- Add health check instruction
- Remove unnecessary files .DS_Store

---

### Task 2 — Docker Host Security Benchmarking

#### Summary Statistics

| Status  |  Count |
|---------|------|
| PASS    |  22  |
| WARN    |  23  |
| FAIL    |  0   |
| INFO    |  29  |
| TOTAL   |  74  |

- 1.1: No separate partition for containers.
    Impact: A lack of isolation can lead to denial of service or integrity risks if Docker exhausts host resources. Remediation: Create a dedicated partition for /var/lib/docker
- 1.5–1.9: Incomplete auditing for Docker daemon, files, directories, service, and socket. Remediation: Configure Linux audit rules for Docker daemon, data directories and service/socket files to log all changes.
    Impact: Without audit trails, malicious or accidental changes may go undetected.
- 2.1: No default bridge isolation—container communication may be unrestricted.
    Impact: Attackers could exploit inter-container network channels. Remediation: Restrict container network traffic on the default bridge via --icc=false and consider user-defined bridges.
- 2.8, 2.18: User namespaces not enabled; containers may acquire new privileges. 
    Impact: Containers can escalate privileges and potentially compromise the host. Remediation: Enable user namespace support by setting "userns-remap" in daemon.json to restrict container privileges. Set "no-new-privileges=true" in container run options to block privilege escalation.
- 2.11: Authorization not enforced for Docker client commands. 
    Impact: Untrusted users may run high-risk admin actions. Remediation: se Docker's authorization plugin or enable RBAC features to restrict client command access to trusted users/groups only.
- 2.12: No centralized/remote logging. 
    Impact: Security events could be missed, complicating incident response. Remediation: configure Docker daemon for remote logging
- 2.14, 2.15: Live restore and userland proxy settings not hardened. 
    Impact: Incomplete state recovery and unnecessary exposed services increase risk. Remediation: Enable live restore, disable userland proxy
- 4.5–4.6: Docker Content Trust and healthchecks not universally enabled. 
    Impact: Image tampering and unhealthy containers might go unnoticed. Remediation: Force image signing verification during pulls via DOCKER_CONTENT_TRUST=1
- 4.6: Missing HEALTHCHECK instructions for many images. 
    Impact: Lack of visibility into container health status could lead to running compromised or malfunctioning services. Remediation: add healthchecks


---

### Task 3 — Deployment Security Configuration Analysis

#### Configuration Comparison Table

| Profile         | Capabilities Dropped | Capabilities Added  | Security Options     | Memory Limit        | CPU Limit  | PIDs Limit | Restart Policy |
|-----------------|---------------------|--------------------|---------------------|---------------------|------------|------------|----------------|
| juice-default   | -                   | -                  | -                   | Unlimited           | Unlimited  | -          | no             |
| juice-hardened  | ALL                 | -                  | no-new-privileges   | 512 MiB (536870912) | Unlimited  | -          | no             |
| juice-production| ALL                 | NET_BIND_SERVICE   | no-new-privileges   | 512 MiB (536870912) | Unlimited  | 100        | on-failure     |

#### Security Measure Analysis

a) --cap-drop=ALL and --cap-add=NET_BIND_SERVICE  
- Linux capabilities are fine-grained privileges that divide root-level powers into distinct permissions for processes.
- Dropping ALL capabilities prevents processes from performing privileged operations, notably blocking many attack vectors involving privilege escalation or kernel interaction.  
- NET_BIND_SERVICE is added back in production to allow binding to low-numbered network ports without root.  
- Security trade-off: adding back NET_BIND_SERVICE grants minimal needed network binding permission but restricts other capabilities, reducing overall attack surface.

b) --security-opt=no-new-privileges  
- This flag prevents a container process from gaining additional privileges through execve calls, meaning no privilege escalation after container start.
- It blocks exploits that rely on gaining elevated permissions inside a running container (e.g., via sudo or setuid binaries).
- Downsides: some legitimate workflows requiring privilege elevation inside container may be blocked; also might interfere with debugging or privileged containers.

c) --memory=512m and --cpus=1.0  
- Without resource limits, a container can consume excessive host CPU/memory, risking DoS to other containers or host.  
- Memory limiting prevents attacks like out-of-memory DoS or fork bombs that exhaust RAM.  
- Setting limits too low risks killing or throttling container under normal operation, causing performance degradation or failures.

d) --pids-limit=100  
- A fork bomb is a DoS attack where a process creates many child processes rapidly to exhaust system process slots.
- PID limiting confines process creation within a container so fork bomb cannot exhaust host process table or degrade other services.
- The right limit balances application needs with security; often requires testing to avoid killing legitimate processes.

e) --restart=on-failure:3  
- This policy restarts the container up to 3 times on failure, enabling resilience to transient errors.  
- Auto-restart is beneficial for service availability but risky if failure results from persistent issues causing restart loops.
- on-failure restarts only on errors; always restarts unconditionally unless stopped manually.


#### Critical Thinking Questions

- Which profile for DEVELOPMENT?  
  Hardened: balanced security and fewer restrictions, easier troubleshooting with less strict limits.

- Which profile for PRODUCTION?  
  Production: maximum hardening with capabilities dropped, resource limits, PID limiting, restart policy for resilience.

- What real-world problem do resource limits solve?  
  Prevent resource exhaustion (CPU, memory) DoS from runaway or malicious containers impacting host or other containers.

- If an attacker exploits Default vs Production, what actions are blocked in Production?  
  Production blocks privilege escalation, unauthorized capability use, fork bombs (via PID limits), excessive resource consumption (memory, CPU), and retries on errors limited.

- What additional hardening would you add?  
  - Run container as non-root user explicitly.  
  - Enable read-only filesystem or immutable root filesystem.  
  - Use seccomp profiles with stricter syscall restrictions (beyond default).  
  - Enable AppArmor or SELinux policies.  
  - Limit network access with network policies or firewalls.  
  - Use runtime security monitoring or scanning.

