# **Lab 9 — Falco and OPA Security Analysis**

## **Part 1: Falco Runtime Security**

### **Baseline Alerts**

After running Falco with the default rule set and monitoring normal container activity, several baseline alerts appeared in `falco.log`. Typical examples include:

| Alert                                | Description                                                                                                                         |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| `File below /etc opened for writing` | Some processes attempted to write configuration files — may be benign during system updates or package installation.                |
| `Terminal shell in container`        | Detected a shell opened inside a container (e.g., via `docker exec -it`), indicating potential debugging or intrusion.              |
| `Unexpected outbound connection`     | A process within a container initiated a network connection to an external address. Could indicate network activity worth auditing. |

These alerts form a **baseline** of normal system operations. They help distinguish legitimate activity (e.g., log writes, package management) from suspicious behavior.

---

### **Custom Rule**

**Rule name:** `Detect Sensitive File Access`
**Purpose:** Detect any process reading or writing files in `/etc`, `/root`, or `/var/lib/docker` — potential indicators of privilege escalation or tampering.

```yaml
- rule: Detect Sensitive File Access
  desc: Detects access to critical system or Docker files
  condition: (open_read or open_write) and fd.name startswith (/etc or /root or /var/lib/docker)
  output: "Sensitive file accessed (user=%user.name process=%proc.name file=%fd.name)"
  priority: WARNING
  tags: [filesystem, security]
```

**When it should fire:**

* Any container or process opens sensitive files in `/etc`, `/root`, or Docker’s internal directories.

**When it should not fire:**

* Legitimate system processes (e.g., Falco itself or `apt`) accessing configuration files during normal updates or service startup.

---

## **Part 2: OPA Policy Enforcement**

### **1. Policy Violations — `juice-unhardened.yaml`**

Running the OPA Conftest policy checks produced the following results:

| Violation                                 | Security Impact                                                                     |
| ----------------------------------------- | ----------------------------------------------------------------------------------- |
| `:latest` image tag                       | Unpredictable image versions — risk of running untested or malicious image updates. |
| Missing `runAsNonRoot: true`              | Container runs as root, giving full host-level privileges if compromised.           |
| Missing `allowPrivilegeEscalation: false` | Allows container processes to gain elevated privileges.                             |
| Missing `readOnlyRootFilesystem: true`    | Filesystem writable → potential tampering or persistence mechanisms.                |
| Missing `capabilities.drop: ["ALL"]`      | Container retains unnecessary Linux capabilities → larger attack surface.           |
| Missing CPU/memory requests and limits    | No resource control → risk of denial of service.                                    |
| Missing readiness/liveness probes         | Application availability and recovery not guaranteed.                               |

**Test summary:**

```
30 tests, 20 passed, 2 warnings, 8 failures, 0 exceptions
```

---

### **2. Hardening Improvements — `juice-hardened.yaml`**

The hardened manifest applied the following secure configurations:

| Change                              | Security Benefit                                |
| ----------------------------------- | ----------------------------------------------- |
| Fixed image version (`v19.0.0`)     | Ensures deterministic and verifiable builds.    |
| `runAsNonRoot: true`                | Prevents root-level execution inside container. |
| `allowPrivilegeEscalation: false`   | Blocks privilege escalation exploits.           |
| `readOnlyRootFilesystem: true`      | Protects filesystem integrity.                  |
| `capabilities.drop: ["ALL"]`        | Removes unnecessary kernel privileges.          |
| Resource limits/requests            | Prevents resource abuse.                        |
| Added readiness and liveness probes | Improves stability and auto-healing.            |

**Test summary:**

```
30 tests, 30 passed, 0 warnings, 0 failures
```

---

### **3. Docker Compose Manifest Results**

The Compose manifest passed all tests:

| Check                    | Status |
| ------------------------ | ------ |
| Non-root user            | ✅      |
| Read-only filesystem     | ✅      |
| Dropped all capabilities | ✅      |
| `no-new-privileges:true` | ✅      |

**Test summary:**

```
15 tests, 15 passed, 0 warnings, 0 failures
```

**Conclusion:**
All OPA security policies were satisfied. Both Kubernetes and Docker Compose manifests demonstrate strong runtime hardening aligned with container security best practices.

