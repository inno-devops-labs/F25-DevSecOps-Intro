# Lab 9 — Monitoring & Compliance: Falco Runtime Detection + Conftest Policies

## Task 1 — Runtime Security Detection with Falco

### Baseline Alerts Observed

Below are notable baseline detections captured during runtime:

| Rule Name | Severity | Description |
|------------|-----------|-------------|
| **Terminal shell in container** | Notice | Triggered when an interactive shell (`/bin/sh`) was opened inside the `lab9-helper` container. Indicates direct shell access, often linked to debugging or potential exploitation. |
| **Detect release_agent File Container Escapes** | Critical | Detected an attempt to write to `/release_agent`, a known container escape vector. |
| **Fileless execution via memfd_create** | Critical | Observed in the event generator, showing in-memory code execution (defense evasion behavior). |
| **Drop and execute new binary in container** | Critical | Execution of a binary not part of the container’s base image — possible persistence or malware drop. |
| **Execution from /dev/shm** | Warning | Scripts executed from a temporary memory filesystem — common in fileless attacks. |
| **Search Private Keys or Passwords / Find AWS Credentials** | Warning | Simulated credential access via the event generator. |
| **Debugfs launched in privileged container** | Warning | Debug filesystem usage indicating potential privilege escalation activity. |
| **Packet socket created in container** | Notice | Container attempting low-level network packet access — unusual for non-network utilities. |

**Summary of triggered events:**
- Events detected: 25
- Rule counts by severity:
  -  CRITICAL: 3
  -  WARNING: 16
  -  NOTICE: 5
  -  INFO: 1

### Custom Rule: `Write Binary Under UsrLocalBin`

**Rule YAML:**
```yaml
- rule: Write Binary Under UsrLocalBin
  desc: Detects writes under /usr/local/bin inside any container
  condition: evt.type in (open, openat, openat2, creat) and 
             evt.is_open_write=true and 
             fd.name startswith /usr/local/bin/ and 
             container.id != host
  output: >
    Falco Custom: File write in /usr/local/bin (container=%container.name user=%user.name file=%fd.name flags=%evt.arg.flags)
  priority: WARNING
  tags: [container, compliance, drift]
```

**Purpose:** Specifically detects file writes under `/usr/local/bin/` directory in any container. This is a focused version of the general drift detection rule.

**Should fire:** When any process creates or opens for writing a file in /usr/local/bin/

**Shouldn't fire:** When a process reads or executes a file from that directory, or when files are written to other directories, or when writes happen on the host itself

## Task 2 — Policy-as-Code with Conftest (Rego)

### Policy Violations in Unhardened Manifest

The unhardened manifest failed **8 critical policies** and had **2 warnings**:

| Violation | Severity | Security Impact |
|-----------|----------|-----------------|
| Missing CPU limits | FAIL | Resource exhaustion attacks, noisy neighbor problems |
| Missing memory limits | FAIL | Memory exhaustion leading to node instability |
| Missing CPU requests | FAIL | Poor scheduling and performance predictability |
| Missing memory requests | FAIL | Inefficient resource allocation |
| allowPrivilegeEscalation not false | FAIL | Container escape and privilege escalation |
| readOnlyRootFilesystem not true | FAIL | File system tampering and persistence |
| runAsNonRoot not true | FAIL | Running as root increases attack surface |
| Using :latest tag | FAIL | Unpredictable updates and versioning issues |
| Missing livenessProbe | WARN | Unable to detect/restart unhealthy containers |
| Missing readinessProbe | WARN | Potential service disruption during deployments 

### Hardening Changes Applied

The hardened manifest successfully addressed all violations:

**Security Context Hardening:**

```
          securityContext:
            runAsNonRoot: true
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]
          resources:
            requests: { cpu: "100m", memory: "256Mi" }
            limits:   { cpu: "500m", memory: "512Mi" }

          readinessProbe:
            httpGet: { path: /, port: 3000 }
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet: { path: /, port: 3000 }
            initialDelaySeconds: 10
            periodSeconds: 20

```
## Analysis of the Docker Compose Manifest Results

The **Docker Compose manifest (`juice-compose.yml`)** was tested with the `compose-security.rego` policy set.  
Overall, it was mostly compliant, showing only a few minor warnings.

---

### Compliant Aspects
- **Non-root user defined:** The container does not run as root, reducing privilege risks.  
- **No privileged mode:** `privileged: false` by default, preserving container isolation.  
- **Limited network exposure:** Only necessary ports are published (e.g., `3000:3000`).  
- **Resource limits present:** CPU and memory limits are configured, preventing resource exhaustion.  


