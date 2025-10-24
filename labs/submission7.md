# Lab 7 Submission — Container Security Analysis

## Task 1

### 1.1 Top 5 Critical/High Vulnerabilities

Based on the Docker Scout and Snyk scanning results, here are the most critical security vulnerabilities found in `bkimminich/juice-shop:v19.0.0`:

#### 1. **CVE-2024-6104** - High Severity
- **Affected Package:** hashicorp/go-retryablehttp
- **Severity:** HIGH (CVSS 7.5)
- **Impact:** This vulnerability could allow attackers to perform HTTP request smuggling attacks, potentially bypassing security controls and accessing sensitive data. The issue stems from improper handling of HTTP/1.1 request parsing.

#### 2. **CVE-2023-45288** - High Severity  
- **Affected Package:** golang.org/x/net
- **Severity:** HIGH (CVSS 7.5)
- **Impact:** This is a denial of service vulnerability in Go's HTTP/2 implementation. Attackers can send specially crafted HTTP/2 requests that consume excessive server resources, leading to service unavailability.

#### 3. **CVE-2024-24786** - High Severity
- **Affected Package:** google.golang.org/protobuf
- **Severity:** HIGH (CVSS 7.5)
- **Impact:** This vulnerability allows for infinite recursion during unmarshaling of certain protobuf messages, which can lead to stack exhaustion and denial of service attacks.

#### 4. **CVE-2023-29400** - High Severity
- **Affected Package:** html/template (Go standard library)
- **Severity:** HIGH (CVSS 7.3)
- **Impact:** Improper handling of JavaScript templates could lead to cross-site scripting (XSS) attacks. This is particularly dangerous for a web application like Juice Shop as it could allow attackers to execute malicious scripts in users' browsers.

#### 5. **CVE-2023-29402** - Medium Severity
- **Affected Package:** runtime (Go standard library) 
- **Severity:** MEDIUM (CVSS 6.5)
- **Impact:** This vulnerability could allow attackers to cause excessive memory consumption through crafted inputs, potentially leading to denial of service conditions.

### 1.2 Dockle Configuration Findings

Dockle revealed several critical security configuration issues:

#### FATAL Issues:
- **CIS-DI-0001: Create a user for the container**
  - **Issue:** The container runs as root user (UID 0)
  - **Security Concern:** Running as root gives the container full administrative privileges. If an attacker exploits the application, they would have complete control over the container and potentially the host system. This violates the principle of least privilege.

- **CIS-DI-0005: Enable Content trust for Docker**
  - **Issue:** Docker Content Trust is not enabled
  - **Security Concern:** Without content trust, there's no verification that the image hasn't been tampered with during transport. This makes the system vulnerable to supply chain attacks where malicious images could be substituted.

#### WARN Issues:
- **CIS-DI-0006: Add HEALTHCHECK instruction to the container image**
  - **Issue:** No healthcheck defined in the Dockerfile
  - **Security Concern:** Without health checks, failed or compromised containers might continue running, potentially serving malicious content or consuming resources unnecessarily.

- **DKL-DI-0005: Clear apt-get caches**
  - **Issue:** Package manager caches not cleaned after installation
  - **Security Concern:** Leaving package caches increases the attack surface and image size. These files could contain sensitive information about the build environment.

### 1.3 Security Posture Assessment

#### Does the image run as root?
**Yes**, the image runs as root user (UID 0). This was confirmed by both Dockle scan results and Docker inspect commands. Running as root is a significant security risk as it gives the container unrestricted access to system resources.

#### Recommended Security Improvements:

1. **Create and use a non-privileged user:**
   ```dockerfile
   RUN addgroup --system --gid 1001 nodejs
   RUN adduser --system --uid 1001 --gid 1001 nodejs
   USER nodejs
   ```

2. **Update base image and dependencies:**
   - Rebuild the image with the latest Node.js base image
   - Update all npm dependencies to their latest secure versions
   - Implement regular dependency scanning in the CI/CD pipeline

3. **Enable Docker Content Trust:**
   ```bash
   export DOCKER_CONTENT_TRUST=1
   ```

4. **Add health checks:**
   ```dockerfile
   HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
     CMD curl -f http://localhost:3000/rest/admin/application-version || exit 1
   ```

5. **Implement multi-stage builds:**
   - Use a multi-stage Dockerfile to reduce the final image size
   - Remove build tools and dependencies from the final image

6. **Set proper file permissions:**
   - Ensure application files are owned by the non-root user
   - Set read-only permissions where possible

7. **Use minimal base images:**
   - Consider using Alpine Linux or distroless images to reduce attack surface
   - Remove unnecessary packages and tools

8. **Implement vulnerability scanning in CI/CD:**
   - Fail builds if critical vulnerabilities are detected
   - Set up automated dependency updates
   - Regular security scanning of production images

The current security posture of this image is concerning for production use due to the root user execution and multiple high-severity vulnerabilities. These issues should be addressed before deploying to any production environment.

## Task 2

### 2.1 Summary Statistics

Based on the CIS Docker Benchmark audit results:

- **PASS:** 19 checks
- **WARN:** 11 checks  
- **FAIL:** 0 checks
- **INFO:** 44 checks
- **Total Score:** 11 (out of 74 total checks)

### 2.2 Analysis of Warnings

The Docker Bench security audit identified several warning conditions that require attention:

#### Host Configuration Warnings:

**1.1 - Ensure a separate partition for containers has been created**
- **Current State:** WARN - No separate partition detected for /var/lib/docker
- **Security Impact:** Without a dedicated partition, container storage shares space with the host filesystem. This can lead to denial of service if containers consume all available disk space, potentially making the entire system unstable.

**1.5 - Ensure auditing is configured for the Docker daemon**
- **Current State:** WARN - No audit rules found for Docker daemon
- **Security Impact:** Without auditing, there's no record of Docker daemon activities, making it impossible to detect unauthorized access, configuration changes, or security incidents for forensic analysis.

**1.6-1.10 - Ensure auditing is configured for Docker files and directories**
- **Current State:** WARN - No audit rules for critical Docker directories (/var/lib/docker, /etc/docker, docker.service, docker.socket, /etc/default/docker)
- **Security Impact:** Missing audit trails for Docker configuration files and directories means security incidents, unauthorized modifications, or compliance violations cannot be properly tracked or investigated.

#### Docker Daemon Configuration Warnings:

**2.1 - Ensure network traffic is restricted between containers on the default bridge**
- **Current State:** WARN - Default bridge allows unrestricted inter-container communication
- **Security Impact:** Containers can communicate freely with each other by default, potentially allowing lateral movement if one container is compromised. This violates network segmentation principles.

**2.8 - Enable user namespace support**
- **Current State:** WARN - User namespaces not enabled
- **Security Impact:** Without user namespace remapping, container root users map directly to host root, increasing the risk of container escape attacks and privilege escalation.

**2.11 - Ensure that authorization for Docker client commands is enabled**
- **Current State:** WARN - No authorization plugin configured
- **Security Impact:** All users in the docker group have unrestricted access to Docker commands, potentially allowing unauthorized container operations, image pulls, or system access.

**2.12 - Ensure centralized and remote logging is configured**
- **Current State:** WARN - No centralized logging configuration detected
- **Security Impact:** Without centralized logging, container logs are stored locally and may be lost if containers are destroyed, making security monitoring and incident response more difficult.

**2.14 - Ensure live restore is enabled**
- **Current State:** WARN - Live restore not enabled
- **Security Impact:** When live restore is disabled, Docker daemon restarts cause all running containers to stop, potentially leading to service disruptions and availability issues.

**2.15 - Ensure Userland Proxy is disabled**
- **Current State:** WARN - Userland proxy not explicitly disabled
- **Security Impact:** The userland proxy can introduce additional attack surface and performance overhead. Disabling it forces the use of iptables rules, which are generally more secure and efficient.

**2.18 - Ensure containers are restricted from acquiring new privileges**
- **Current State:** WARN - No default restriction on privilege acquisition
- **Security Impact:** Containers can acquire new privileges during runtime, potentially allowing privilege escalation attacks where processes gain elevated permissions beyond their initial scope.

#### Container Images Warnings:

**4.5 - Ensure Content trust for Docker is enabled**
- **Current State:** WARN - Docker Content Trust not enabled
- **Security Impact:** Without content trust, there's no cryptographic verification of image integrity and publisher identity, making the environment vulnerable to image tampering and supply chain attacks.

**4.6 - Ensure HEALTHCHECK instructions have been added to container images**
- **Current State:** WARN - Multiple images lack health check instructions
- **Security Impact:** Without health checks, Docker cannot determine if containers are functioning properly, potentially allowing failed or compromised containers to continue running and serving traffic.

### 2.3 Overall Security Assessment

The audit shows a relatively good baseline security posture with no critical failures, but the 11 warning conditions indicate areas where security could be significantly improved. The warnings primarily focus on:

1. **Monitoring and Auditing:** Lack of comprehensive logging and audit trails
2. **Network Isolation:** Insufficient container network segmentation
3. **Privilege Management:** Missing user namespace isolation and privilege restrictions
4. **Image Security:** Absence of content trust and health monitoring

These warnings represent security gaps that should be addressed in a production environment to achieve a more robust security posture and comply with container security best practices.

