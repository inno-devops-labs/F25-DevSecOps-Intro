### Task 1

1. **Top 5 Critical/High Vulnerabilities**

Below are the **Top 5 Critical and High vulnerabilities** discovered in the `bkimminich/juice-shop:v19.0.0` Docker image:

| CVE ID                                                                           | Affected Package   | Severity     | Impact                      |
| -------------------------------------------------------------------------------- | ------------------ | ------------ | --------------------------- |
| [SNYK-JS-MARSDB-480405](https://security.snyk.io/vuln/SNYK-JS-MARSDB-480405)     | marsdb@0.6.11      | **Critical** | Arbitrary Code Injection    |
| [SNYK-JS-VM2-5537100](https://security.snyk.io/vuln/SNYK-JS-VM2-5537100)         | vm2@3.9.17         | **Critical** | Sandbox Bypass              |
| [SNYK-JS-VM2-5772823](https://security.snyk.io/vuln/SNYK-JS-VM2-5772823)         | vm2@3.9.17         | **Critical** | Remote Code Execution (RCE) |
| [SNYK-JS-VM2-5772825](https://security.snyk.io/vuln/SNYK-JS-VM2-5772825)         | vm2@3.9.17         | **Critical** | Remote Code Execution (RCE) |
| [SNYK-JS-MULTER-10299078](https://security.snyk.io/vuln/SNYK-JS-MULTER-10299078) | multer@1.4.5-lts.2 | **High**     | Uncaught Exception          |

2. **Dockle Configuration Findings**

   * No issues were detected (which is unusual).

3. **Security Posture Assessment**

   * Does the image run as root? – No
   * Recommended improvements:

     * Implement continuous image scanning
     * Use signed and verified base images
     * Apply automated dependency updates

---

### Task 2

**Summary Statistics**

Total PASS/WARN/FAIL/INFO counts:

INFO — 116
WARN — 62
PASS — 24
FAIL — 0

**Failures and Security Impact:**

* No failures detected.

**Recommended Improvements:**

* Add health checks in Dockerfiles
* Enable user namespaces to isolate container users from host users
* Require authorization for Docker client commands
* Configure centralized remote logging for better monitoring
* Enable live restore for container persistence after daemon restarts
* Disable the userland proxy to reduce unwanted network exposure
* Restrict privilege escalation for all containers

---

### Task 3

## Configuration Comparison

| Setting          | Default     | Hardened                       | Production                     |
| ---------------- | ----------- | ------------------------------ | ------------------------------ |
| Capabilities     | All enabled | Drop ALL, Add NET_BIND_SERVICE | Drop ALL, Add NET_BIND_SERVICE |
| Security Options | None        | no-new-privileges              | no-new-privileges              |
| Memory Limit     | Unlimited   | 512MB                          | 512MB                          |
| CPU Limit        | Unlimited   | Unlimited                      | 1.0 CPU                        |
| PID Limit        | Unlimited   | Unlimited                      | 100                            |
| Restart Policy   | None        | None                           | On-failure:3                   |

## Security Analysis

**Capabilities:**

* Linux capabilities separate root privileges into smaller sets
* Dropping all capabilities prevents privilege escalation
* `NET_BIND_SERVICE` is required for ports 80/443

**no-new-privileges:**

* Prevents binaries from escalating privileges
* Stops attackers from gaining root access

**Resource Limits:**

* Protects against denial-of-service (DoS) and resource abuse
* Ensures fair resource distribution among containers
* Must be tuned to avoid unnecessary crashes

**PID Limit (100):**

* Protects against fork bombs
* Prevents exhaustion of the process table

**Restart Policy:**

* Automatically restarts failed containers (up to 3 times)
* Increases availability but may hide persistent issues

**Development Profile:**

* Use the *Default* profile
* Minimal restrictions for debugging and full access for testing

**Production Profile:**

* Use the *Production* profile
* Strong security via dropped capabilities
* Resource and PID limits to prevent DoS
* Controlled restarts for stability

**Real-world benefit of resource limits:**
They prevent “noisy neighbor” problems where a single container monopolizes host resources, affecting others.

**If an attacker compromises Default vs Production:**
Production setup blocks:

* Privilege escalation (due to `no-new-privileges`)
* Resource abuse (memory/CPU limits)
* Fork bombs (PID limit)
* Escape attempts (dropped capabilities)

**Additional Hardening Suggestions:**

* Mount the root filesystem as read-only
* Enable user namespace remapping
* Use seccomp profiles to restrict system calls
* Perform regular vulnerability scans
* Define network policies to control inter-container traffic
