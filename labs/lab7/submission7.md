# Task 1 — Image Vulnerability & Configuration Analysis

## Top 5 Critical/High Vulnerabilities

| CVE ID | Affected Package (Version) | Severity | Impact / Description |
| --- | --- | --- | --- |
| **CVE-2023-37903** | vm2 (3.9.17) | **Critical (9.8)** | OS Command Injection: attacker-supplied input may execute arbitrary OS commands inside the VM sandbox. |
| **CVE-2019-10744** | lodash (2.4.2) | **Critical (9.1)** | Prototype Pollution: allows modification of object prototypes, enabling data tampering or remote code execution. |
| **CVE-2015-9235** | jsonwebtoken (0.1.0, 0.4.0) | **Critical (9.8)** | Improper Input Validation: may allow forged or bypassed JWT tokens, leading to authentication bypass. |
| **CVE-2023-46233** | crypto-js (3.3.0) | **Critical (9.1)** | Weak cryptographic algorithm: may leak or expose sensitive data due to insecure hashing methods. |
| **CVE-2021-44906** | minimist (0.2.4) | **Critical (9.8)** | Argument injection: crafted inputs could override application parameters and execute arbitrary code. |

## Dockle Configuration Findings

| Check ID     | Level | Finding                                               | Why it matters                                                                                                    |
|--------------|-------|-------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------|
| **CIS-DI-0005** | INFO  | Content trust not enabled (DOCKER_CONTENT_TRUST=1)    | Without content trust, images aren’t verified for integrity and authenticity — risk of pulling tampered images.   |
| **CIS-DI-0006** | INFO  | No HEALTHCHECK instruction found                      | Liveness monitoring is missing; orchestrators like Docker Swarm / Kubernetes can’t automatically detect unhealthy containers. |
| **DKL-LI-0003** | INFO  | Unnecessary files (.DS_Store in source tree)         | Increases image bloat and may leak metadata from developer systems.                                               |
| **DKL-LI-0001** | SKIP  | Unable to verify empty passwords (no `/etc/shadow` found) | Not applicable to distroless image, but worth confirming runtime user setup.                                     |

## Security Posture Assessment

**Security Posture Assessment**

**Runtime User**

The OWASP Juice Shop image runs as the root user by default (this is common for older Node images). If an application exploit occurs, this increases the potential damage.

**Risk Summary**

- Multiple critical and high vulnerabilities remain unpatched.
- Health monitoring and content-trust controls are not enabled.
- The image likely executes with elevated privileges.

**Recommended Improvements**

1. Change the user running the application:
   - Add `USER node` or specify a dedicated UID in the Dockerfile to run the container as a non-root user.

2. Update dependencies:
   - Upgrade to the following fixed versions:
     - `jsonwebtoken` to version 9.0.0 or higher;
     - `vm2` to version 3.9.18 or higher;
     - `multer` to version 2.0.2 or higher;
     - `lodash` to version 4.17.21 or higher.

3. Optimize the Docker image:
   - Use multi-stage builds to exclude development artifacts (e.g., `node_modules/.DS_Store`).

4. Enhance security measures:
   - Enable content trust by exporting the environment variable `DOCKER_CONTENT_TRUST=1` and signing images.
   - Add a `HEALTHCHECK` instruction to monitor the liveness of the container.

5. Implement continuous security scanning:
   - Integrate Docker Scout and Snyk into CI/CD pipelines for periodic scanning.

# Task 2 — Docker Host Security Benchmarking

## Summary Statistics

| Result Type | Count | Description |
| --- | --- | --- |
| **PASS** | 36 | Controls properly configured and compliant |
| **WARN** | 33 | Potential security issues that require attention |
| **FAIL** | 0 | No outright failures detected |
| **INFO** | 27 | Informational checks or configuration notes |
| **NOTE** | 9 | Non-critical observations / best practice reminders |
| **TOTAL CHECKS** | **105** | Overall compliance score: **18** |

## Analysis of Warnings & Potential Failures

| Section | Finding | Security Impact | Recommended Remediation |
| --- | --- | --- | --- |
| **1.1** | No separate partition for Docker data (`/var/lib/docker`) | File system exhaustion on host may impact OS stability and security | Mount `/var/lib/docker` on a dedicated partition to isolate container storage. |
| **1.5–1.10** | Auditing not configured for Docker daemon, socket, and related directories | Limited traceability; compromises undetected activities | Enable `auditd` rules for Docker binaries, configs, and sockets to record all access. |
| **2.1** | Container network isolation on default bridge not enforced | Containers can communicate freely — risk of lateral movement | Use custom user-defined bridge networks or `--icc=false` to restrict inter-container communication. |
| **2.8** | User namespace support disabled | Containers share host UID/GID space; privilege escalation possible | Enable user namespace remapping in `/etc/docker/daemon.json`. |
| **2.11–2.12** | Authorization and centralized logging not configured | Missing accountability for Docker API access and weak auditing trail | Configure `--authorization-plugin` and ship logs to a centralized system (e.g., Fluentd, ELK). |
| **2.14–2.15** | Live restore not enabled; userland proxy enabled | Containers may restart insecurely or expose unnecessary ports | Add `"live-restore": true` and `"userland-proxy": false` in `daemon.json`. |
| **2.18** | Containers not restricted from acquiring new privileges | Allows privilege escalation via `setuid` binaries | Start containers with `--security-opt=no-new-privileges`. |
| **4.5–4.6** | Docker Content Trust & HEALTHCHECK missing | Unsigned images and no health monitoring degrade integrity and availability | Export `DOCKER_CONTENT_TRUST=1`; define `HEALTHCHECK` in Dockerfiles. |
| **5.2** | SELinux not enforced | Reduced mandatory access control on container processes | Enable SELinux and use `--security-opt=label:type:container_t`. |
| **5.10–5.12** | No memory/CPU limits; writable root filesystem | Containers can exhaust host resources and modify filesystem | Use `--memory`, `--cpus`, and `--read-only` flags. |
| **5.13** | Ports bound to `0.0.0.0` | Containers exposed to all interfaces, increasing attack surface | Bind to specific host IP or network interface only. |
| **5.14** | Restart policy not limited | Could lead to infinite restart loops after compromise | Use `--restart=on-failure:5` for controlled resilience. |
| **5.25** | Privilege restriction not applied | Containers may gain new privileges during runtime | Always run with `--security-opt=no-new-privileges`. |
| **5.26** | Health check not set | Runtime issues undetected until failure occurs | Add `HEALTHCHECK` directives to Dockerfiles or via `docker run`. |
| **5.28** | No PID limit configured | Susceptible to fork bombs or runaway processes | Add `--pids-limit=<value>` (e.g., 100) for all containers. |

# Task 3 — Deployment Security Configuration Analysis

## Configuration Comparison Table

| Profile | Capabilities (Dropped/Added) | Security Options | Memory Limit | CPU Limit | PID Limit | Restart Policy |
| --- | --- | --- | --- | --- | --- | --- |
| **Default** | None dropped or added | None | Unlimited | Unlimited | Unlimited | `no` |
| **Hardened** | `--cap-drop=ALL` | `--security-opt=no-new-privileges` | 512 MB | 1 CPU | None | `no` |
| **Production** | `--cap-drop=ALL`, `--cap-add=NET_BIND_SERVICE` | `--security-opt=no-new-privileges`, `--security-opt=seccomp=default` | 512 MB | 1 CPU | 100 | `on-failure:3` |

## Security Measure Analysis

### Container Security Configuration Options

**a) `--cap-drop=ALL` and `--cap-add=NET_BIND_SERVICE`**

**What are Linux capabilities?**
Linux capabilities divide root privileges into specific, fine-grained permissions. Examples include the ability to bind to low-numbered ports, mount filesystems, or change the system time. Containers can selectively retain or remove these capabilities to reduce their privileges and improve security.

**Attack vector prevented by dropping all capabilities:**
Dropping all capabilities prevents attackers from escalating privileges through kernel-level or system-level operations. This includes actions like changing file ownership, modifying network settings, or loading kernel modules.

**Why add back `NET_BIND_SERVICE`?**
This capability allows a container to bind to ports below 1024, such as the standard HTTP (80) and HTTPS (443) ports. Without it, a non-root process cannot serve web traffic on these standard ports.

**Trade-off:**
While dropping capabilities significantly reduces the risk of host compromise, you may need to re-add certain capabilities to maintain functionality, especially for network services.

---

**b) `--security-opt=no-new-privileges`**

**What it does:**
This option ensures that processes inside a container cannot gain additional privileges, even if they encounter setuid binaries. It prevents privilege escalation through misconfigured binaries or libraries.

**Attack prevention:**
It blocks exploitation of setuid binaries and thwarts sandbox escape attempts where processes try to execute with elevated privileges.

**Downsides:**
The downsides are minimal. It might interfere with containers that rely on legitimate setuid binaries, but most modern container images (e.g., Node.js applications) function without issue.

---

**c) `--memory=512m` and `--cpus=1.0`**

**Without limits:**
A single container could consume all the host’s resources, starving other workloads and potentially causing a denial-of-service situation.

**Attacks prevented:**
These limits prevent resource exhaustion (DoS attacks) where malicious or runaway processes consume excessive amounts of memory or CPU.

**Risk of setting limits too low:**
If the limits are set below the operational needs of the application, it may crash or experience degraded performance. It’s important to tune these limits based on testing and actual usage.

---

**d) `--pids-limit=100`**

**What is a fork bomb?**
A fork bomb is a malicious or faulty process that continuously spawns new processes, eventually exhausting the system’s supply of process IDs (PIDs) and causing the host to freeze.

**How PID limiting helps:**
Setting a PID limit restricts the number of processes a container can create, thereby isolating runaway workloads and preventing them from affecting the entire system.

**Determining the right limit:**
To set an appropriate PID limit, measure the typical number of PIDs your container uses and add a safety buffer. For example, if your application normally uses 30 PIDs, you might set the limit to around 100.

---

**e) `--restart=on-failure:3`**

**What it does:**
This option automatically restarts a container if it exits with a non-zero status, up to a maximum of three times.

**When it’s beneficial:**
It helps the system recover from transient errors, network timeouts, or brief service disruptions.

**When it’s risky:**
Using `--restart=on-failure:3` can mask repeated crashes caused by bugs or attacks. Using `--restart=always` is even riskier because it can lead to infinite restart loops, which might hide ongoing security issues.

**Comparison:**
`- on-failure` limits restarts to actual crashes, providing a balance between availability and security.
`- always` restarts the container regardless of the stop reason, which can be dangerous from a security perspective.

---

### Critical Thinking Questions

**1. Which profile is best for DEVELOPMENT? Why?**
- **Answer:** Default. Developers require flexibility and quick rebuilds. Security restrictions, such as dropped capabilities and resource limits, can slow down debugging and testing processes.

**2. Which profile is best for PRODUCTION? Why?**
- **Answer:** Production. This profile offers comprehensive hardening, including dropped capabilities, restricted privileges, resource controls, PID limits, and a controlled restart policy. It strikes a balance between security and availability.

**3. What real-world problem do resource limits solve?**
- **Answer:** They prevent Denial-of-Service (DoS) attacks caused by memory or CPU exhaustion, whether due to bugs, misconfigurations, or malicious workloads.

**4. If an attacker exploits Default vs Production, what actions are blocked in Production?**
- **Answer:** In the Production profile, attackers are unable to:
  - Escalate privileges (due to `no-new-privileges`).
  - Spawn an unlimited number of processes (due to `pids-limit`).
  - Consume excessive system resources (due to memory and CPU limits).
  - Bind to privileged ports without permission (due to `cap-drop=ALL`).
These measures limit the potential damage from an exploit.

**5. What additional hardening would you add?**
- **Use a read-only root filesystem (`--read-only`).**
- **Restrict network access with `--network=none` if feasible.**
- **Apply AppArmor or SELinux profiles for mandatory access control (MAC) enforcement.**
- **Enable Docker Content Trust to ensure image integrity.**
- **Integrate vulnerability scanning into the CI/CD pipeline before deployment.**
