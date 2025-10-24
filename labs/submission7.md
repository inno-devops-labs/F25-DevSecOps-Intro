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

