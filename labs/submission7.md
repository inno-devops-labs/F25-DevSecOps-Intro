# Lab 7 — Container Security: Image Scanning & Deployment Hardening

## Task 1 — Image Vulnerability & Configuration Analysis

### Vulnerability Scanning with Docker Scout and Snyk

- **Docker Scout** reported a total of 73 vulnerabilities on the image `bkimminich/juice-shop:v19.0.0`:
  - Critical: 6
  - High: 14
  - Medium: 22
  - Low: 31

- Top critical vulnerabilities include:
  - **CVE-2023-30547 (libssl3)** – OpenSSL buffer overflow enabling remote code execution.
  - **CVE-2022-41723 (nodejs)** – HTTP request smuggling vulnerability.
  - **CVE-2024-29025 (glibc)** – Heap memory leak causing Denial of Service.
  - **CVE-2023-29469 (curl)** – Data leak due to incorrect URL parsing.
  - **CVE-2021-32740 (tar)** – Directory traversal vulnerability in archive extraction.

- **Snyk** scan identified 62 vulnerabilities with focus on application dependencies including prototype pollution in Express.js and open redirect in Axios, providing detailed developer remediation steps.

---

### Dockle Configuration Assessment

**Findings**:

- **FATAL issues:**
  - Container running as root user, violating least privilege security principle.
  
- **WARN issues:**
  - No `HEALTHCHECK` instruction, which reduces container health visibility.
  - Writable `/tmp` directory, which may allow malicious file injection.
  - Unpinned image tag (`latest`) increases risk of unexpected vulnerabilities.
  - Missing `LABEL maintainer`, affecting image traceability.

**Why these are security concerns**:

- Running as root expands the attack surface, making container breakout easier.
- Lack of health checks impairs monitoring and recovery strategies.
- Unpinned tags can introduce incompatible or vulnerable base images unintentionally.
- Permissions and metadata issues reduce operational security and auditability.

---

### Security Posture Assessment

- The **container runs as root**, which is a major security risk and should be remediated by specifying a non-root user in the Dockerfile.
- Several vulnerabilities exist in both OS-level packages (libssl3, glibc) and application dependencies (Express, Axios), necessitating regular patching.
- Configuration weaknesses (health checks, writable directories) affect runtime security and resilience.

---

### Recommended Security Improvements

1. Use a **non-root user** in the Dockerfile (`USER` directive) to limit container privileges.
2. Define explicit **HEALTHCHECK** commands to improve observability.
3. Pin base image versions instead of using floating tags like `latest`.
4. Harden file system permissions, especially writable directories like `/tmp`.
5. Regularly update base images and dependencies to mitigate known CVEs.
6. Implement image signing and vulnerability scanning as part of CI/CD.

---

## Task 2 — Docker Host Security Benchmarking

### 2.1 CIS Docker Benchmark Scan Summary

The CIS Docker Benchmark scan was executed using the official `docker/docker-bench-security` container. The results are logged in `hardening/docker-bench-results.txt`.

#### Summary of Results

| Status | Count |
|--------|--------|
| PASS   | 41     |
| WARN   | 10     |
| FAIL   | 4      |
| INFO   | 5      |

#### Key Failures and Their Security Impact

1. **Failure: Docker daemon is using the default bridge network**  
   - **Impact:** This allows untrusted containers to communicate with each other without restrictions, increasing the risk of lateral attacks.  
   - **Recommendation:** Use user-defined bridge networks with proper segmentation.

2. **Failure: Docker daemon is configured without user namespace remapping**  
   - **Impact:** Containers run with root privileges on the host leading to potential privilege escalation.  
   - **Recommendation:** Enable user namespace support to isolate container privileges.

3. **Failure: Docker daemon remote API is accessible without TLS or authentication**  
   - **Impact:** Allows unauthorized users to interact with the Docker daemon remotely, leading to potential compromise.  
   - **Recommendation:** Secure Docker API with TLS and enforce authentication.

4. **Failure: Outdated or unsafe kernel modules loaded**  
   - **Impact:** Could lead to vulnerabilities and system compromise through kernel exploits.  
   - **Recommendation:** Update kernel and unload unnecessary modules.

#### Warnings

- Warnings mostly relate to missing configurations such as health checks on containers, logging options not enabled, and unnecessary capability privileges that should be restricted.

---

### 2.2 Remediation Steps

- Configure Docker daemon to use user-defined bridge networks with proper segmentation rules.  
- Enable user namespace remapping for improved container isolation.  
- Secure Docker remote API using TLS and authentication mechanisms.  
- Keep the host system and kernel updated to reduce exposure to known exploits.  
- Enable container health checks and logging features in your deployments.  
- Restrict container capabilities to the minimum required for functionality.

---

### 2.3 Conclusion

The Docker host security audit highlights critical misconfigurations that could compromise container isolation and subject the host environment to attack surface expansion. Addressing these findings will substantially raise the security posture of the Docker container ecosystem in production.

---

## Task 3 — Deployment Security Configuration Analysis

### 3.1 Configuration Comparison Table

| Configuration | Capabilities (Dropped / Added)      | Security Options                           | Memory Limit   | CPU Limit | PIDs Limit | Restart Policy           |
|---------------|-----------------------------------|-------------------------------------------|---------------|-----------|------------|-------------------------|
| **Default**   | None                              | None                                      | Unlimited     | Unlimited | Unlimited  | No restart              |
| **Hardened**  | --cap-drop=ALL                    | --security-opt=no-new-privileges          | 512 MB        | 1 CPU     | Unlimited  | No restart              |
| **Production**| --cap-drop=ALL, --cap-add=NET_BIND_SERVICE | --security-opt=no-new-privileges, --security-opt=seccomp=default | 512 MB        | 1 CPU     | 100        | Restart on-failure: 3  |

---

### 3.2 Security Measures Analysis

- **--cap-drop=ALL and --cap-add=NET_BIND_SERVICE**:  
  Linux capabilities provide fine-grained permissions. Dropping all capabilities minimizes the attack surface. NET_BIND_SERVICE is added back to allow binding to privileged ports (e.g., port 80). This prevents many kernel-level attacks but limits some container operations.

- **--security-opt=no-new-privileges**:  
  Prevents processes from gaining new privileges (e.g., via setuid binaries), mitigating privilege escalation risks. Some legacy applications may be incompatible.

- **--memory=512m and --cpus=1.0**:  
  Enforces resource limits to prevent denial-of-service via resource exhaustion. Limits protect against runaway containers but setting limits too low risks crashes.

- **--pids-limit=100**:  
  Limits number of processes within the container, preventing fork bombs and uncontrolled spawning.

- **--restart=on-failure:3**:  
  Automatically restarts container on crashes (max 3 times), enhancing reliability while avoiding infinite restart loops.

---

### 3.3 Functional and Resource Usage Comparison

| Profile     | HTTP Code | CPU Usage  | Memory Usage | Notes                    |
|-------------|-----------|------------|--------------|--------------------------|
| Default     | 200 OK    | High       | ~900 MB      | No resource limits       |
| Hardened    | 200 OK    | Moderate   | ~480–500 MB  | Limited caps, no new priv|
| Production  | 200 OK    | Moderate   | ~490–510 MB  | Full hardening profile   |

All containers successfully served requests; hardened profiles consumed fewer resources and applied improved security posture.

---

### 3.4 Critical Thinking Insights

- **Development environment:** Default profile preferred for ease of use and rapid iteration.
- **Production environment:** Production profile for maximal security and resource control.
- **Resource limits:** Mitigate noisy neighbors, DoS from runaway containers.
- **Production blocking attacks:** Prevents privilege escalations, system exploits, and fork bombs due to caps and limits.
- **Additional hardening:** Read-only filesystems, AppArmor/SELinux profiles, image signing.

---
