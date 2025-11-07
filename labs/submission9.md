# Lab 9 Submission — Falco Runtime Detection & Conftest Policies

## Task 1 — Runtime Security Detection with Falco

### Baseline Alerts Observed

From the Falco logs (`labs/lab9/falco/logs/falco.log`), the following baseline alerts were captured:

#### 1. Terminal Shell in Container (Notice)
**Alert:**
```
2025-11-07T15:47:49.794300121+0000: Notice A shell was spawned in a container with an attached terminal
container=lab9-helper user=root process=sh command=sh -lc echo hello-from-shell
```

**Analysis:** This alert was triggered when executing a shell command inside the `lab9-helper` container. This is expected behavior for interactive shell access and demonstrates Falco's ability to detect shell spawns in containers, which is a common indicator of potential malicious activity or unauthorized access.

#### 2. Custom Rule Alert — Write Binary Under UsrLocalBin (Warning)
**Alert:**
```
2025-11-07T15:49:15.589678686+0000: Warning Falco Custom: File write in /usr/local/bin
container=lab9-helper user=root file=/usr/local/bin/custom-rule.txt
```

**Analysis:** This alert was triggered by our custom rule when a file was written to `/usr/local/bin` inside the container. This demonstrates container drift detection — unauthorized modifications to binary directories that could indicate compromise or malicious activity.

#### 3. Additional Test Events from Event Generator

The Falco event generator produced multiple security-relevant alerts, including:
- **Critical:** Container escape attempts via `release_agent` file
- **Critical:** Fileless execution via `memfd_create`
- **Critical:** Execution of binaries not part of the base image
- **Warning:** Sensitive file reads (`/etc/shadow`)
- **Warning:** Network-based attacks (netcat remote code execution)
- **Warning:** Process injection attempts (ptrace)

These events validate that Falco is correctly detecting a wide range of security threats and attack patterns.

### Custom Rule Analysis

**Rule:** `Write Binary Under UsrLocalBin`

**Location:** `labs/lab9/falco/rules/custom-rules.yaml`

**Purpose:** This custom rule detects writes to `/usr/local/bin` inside containers, which is a critical security indicator for:
- Container drift (unauthorized changes to container filesystem)
- Potential malware installation
- Binary tampering or backdoor placement

**When it should fire:**
- Any write operation (open, openat, openat2, creat) with write flags
- Target path starts with `/usr/local/bin/`
- Event occurs inside a container (not on the host)

**When it shouldn't fire:**
- Read-only operations
- Writes to other directories (e.g., `/tmp`, `/var/log`)
- Operations on the host filesystem (`container.id == host`)

**Tuning considerations:**
- The rule uses `WARNING` priority, which is appropriate for drift detection
- The condition `container.id != host` ensures we only detect container events
- The rule could be tuned to exclude specific trusted containers if needed by adding exceptions

---

## Task 2 — Policy-as-Code with Conftest (Rego)

### Policy Violations in Unhardened Manifest

The unhardened manifest (`juice-unhardened.yaml`) failed 8 policy checks and generated 2 warnings:

#### Failures (Security Violations):

1. **Missing resources.limits.cpu** — Without CPU limits, a container can consume unlimited CPU resources, leading to:
   - Resource exhaustion attacks (DoS)
   - Noisy neighbor problems affecting other workloads
   - Unpredictable performance and cost overruns

2. **Missing resources.limits.memory** — Without memory limits, containers can cause:
   - OOM (Out-of-Memory) kills of other containers
   - Host system instability
   - Memory exhaustion attacks

3. **Missing resources.requests.cpu** — Missing CPU requests prevent:
   - Proper resource scheduling and placement
   - Quality of Service (QoS) guarantees
   - Predictable performance

4. **Missing resources.requests.memory** — Missing memory requests prevent:
   - Effective resource allocation planning
   - Pod scheduling decisions based on available resources

5. **allowPrivilegeEscalation not set to false** — Allows processes to gain additional privileges beyond their initial set, enabling:
   - Privilege escalation attacks
   - Bypass of security controls
   - Increased attack surface

6. **readOnlyRootFilesystem not set to true** — Writable root filesystem allows:
   - Malware persistence
   - Unauthorized file modifications
   - Container drift and tampering

7. **runAsNonRoot not set to true** — Running as root (UID 0) provides:
   - Full system access within the container
   - Potential for container escape if combined with other vulnerabilities
   - Violation of principle of least privilege

8. **Uses disallowed :latest tag** — The `:latest` tag is problematic because:
   - Unpredictable image versions (can change without notice)
   - Difficult to track and audit deployments
   - Breaks reproducibility and rollback capabilities
   - Security patches cannot be verified against specific versions

#### Warnings (Best Practices):

1. **Missing readinessProbe** — Without readiness probes:
   - Traffic may be routed to containers that aren't ready
   - Application startup issues may go undetected
   - Poor user experience during deployments

2. **Missing livenessProbe** — Without liveness probes:
   - Deadlocked or unresponsive containers won't be restarted
   - Application failures may persist undetected
   - Reduced system reliability

### Hardening Changes in Hardened Manifest

The hardened manifest (`juice-hardened.yaml`) addresses all policy violations:

#### Security Context Hardening:
```yaml
securityContext:
  runAsNonRoot: true                    # ✅ Addresses runAsNonRoot violation
  allowPrivilegeEscalation: false       # ✅ Prevents privilege escalation
  readOnlyRootFilesystem: true           # ✅ Prevents unauthorized writes
  capabilities:
    drop: ["ALL"]                        # ✅ Drops all capabilities (additional hardening)
```

#### Resource Management:
```yaml
resources:
  requests: { cpu: "100m", memory: "256Mi" }  # ✅ Addresses missing requests
  limits:   { cpu: "500m", memory: "512Mi" }  # ✅ Addresses missing limits
```

#### Image Tag Fix:
```yaml
image: bkimminich/juice-shop:v19.0.0    # ✅ Uses specific version instead of :latest
```

#### Health Checks:
```yaml
readinessProbe:                         # ✅ Addresses readinessProbe warning
  httpGet: { path: /, port: 3000 }
  initialDelaySeconds: 5
  periodSeconds: 10

livenessProbe:                          # ✅ Addresses livenessProbe warning
  httpGet: { path: /, port: 3000 }
  initialDelaySeconds: 10
  periodSeconds: 20
```

**Result:** The hardened manifest passes all Conftest policy checks (30 tests, 30 passed, 0 warnings, 0 failures).

### Docker Compose Manifest Analysis

The Docker Compose manifest (`juice-compose.yml`) was tested against `compose-security.rego` policies:

**Result:** All 15 tests passed with no warnings or failures.

**Compliance Analysis:**

The Compose manifest implements security best practices:

1. **Non-root user:** `user: "10001:10001"` — Runs as non-root user (UID/GID 10001)
2. **Read-only filesystem:** `read_only: true` — Prevents unauthorized writes to root filesystem
3. **Temporary filesystem:** `tmpfs: ["/tmp"]` — Provides writable `/tmp` for applications that need it
4. **Capability dropping:** `cap_drop: ["ALL"]` — Drops all Linux capabilities, following principle of least privilege
5. **Security options:** `security_opt: ["no-new-privileges:true"]` — Prevents privilege escalation (though this is a warning, not a failure in the policy)

**Comparison with Kubernetes Hardening:**

The Docker Compose manifest achieves similar security posture to the hardened Kubernetes manifest:
- Both run as non-root users
- Both use read-only root filesystems (with tmpfs for writable areas)
- Both drop all capabilities
- Both use specific image tags (v19.0.0)

The main difference is that Docker Compose doesn't have built-in resource limits (CPU/memory), which would need to be configured at the Docker daemon level or through Docker Compose v3+ deploy.resources if needed.

---

## Summary

This lab successfully demonstrated:

1. **Falco Runtime Detection:** Falco correctly detected baseline security events (shell spawns, file writes) and our custom rule successfully identified container drift in binary directories. The event generator validated Falco's ability to detect a wide range of attack patterns.

2. **Policy-as-Code with Conftest:** The Rego policies effectively identified 8 critical security misconfigurations in the unhardened manifest. The hardened manifest addressed all violations, demonstrating how policy-as-code enforces security best practices and prevents insecure deployments.

3. **Security Hardening:** Both Kubernetes and Docker Compose manifests can achieve strong security postures through proper configuration of security contexts, resource limits, and least-privilege principles.

