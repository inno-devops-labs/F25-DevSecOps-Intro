# Lab 9 — Monitoring & Compliance: Falco Runtime Detection + Conftest Policies

---

## Task 1 — Runtime Security Detection with Falco

### 1. Baseline Alerts Observed from falco.log

**A) Terminal Shell in Container**

- **Alert**: `Terminal shell in container`
- **Priority**: Notice
- **Trigger**: When you executed `docker exec -it lab9-helper /bin/sh -lc 'echo hello-from-shell'`
- **Evidence**:
    - Process: `sh -lc echo hello-from-shell`
    - User: `root`
    - Container: `lab9-helper` (alpine:3.19)
    - This is a standard Falco rule that detects shell sessions in containers

**B) Custom Rule Alert**

- **Alert**: `Write Binary Under UsrLocalBin` (Your custom rule)
- **Priority**: Warning
- **Trigger**: When you executed `docker exec --user 0 lab9-helper /bin/sh -lc 'echo custom-test > /usr/local/bin/custom-rule.txt'`
- **Evidence**:
    - File: `/usr/local/bin/custom-rule.txt`
    - Flags: `O_LARGEFILE|O_TRUNC|O_CREAT|O_WRONLY|O_F_CREATED|FD_UPPER_LAYER`
    - User: `root`
    - Container: `lab9-helper`

### 2. Custom Rule Purpose and Firing Conditions

**Custom Rule**: `Write Binary Under UsrLocalBin`

**Purpose**:

- Detect unauthorized file writes to `/usr/local/bin/` directory within containers
- Monitor for potential container drift or malicious binary installation
- Complement existing Falco drift detection rules with more specific monitoring

**When it SHOULD fire**:

- Any write operation (`open`, `openat`, `openat2`, `creat`) with write flags
- Target path starts with `/usr/local/bin/`
- Operation occurs inside a container (`container.id != host`)
- Examples: Installing binaries, modifying existing files in `/usr/local/bin/`

**When it SHOULD NOT fire**:

- Read-only operations on `/usr/local/bin/` files
- File operations on the host system (not in containers)
- Writes to other directories like `/usr/bin/`, `/bin/`, `/tmp/`
- Operations by trusted system processes during legitimate package management

---

## Task 2 — Policy-as-Code with Conftest (Rego)

### 1. Policy Violations from Unhardened Manifest

**8 FAILED Policies:**

- `:latest` tag - mutable, unpredictable
- Missing `runAsNonRoot` - runs as root (privilege risk)
- Missing `allowPrivilegeEscalation: false` - privilege escalation risk
- Missing `readOnlyRootFilesystem` - writable FS allows malware
- Missing `capabilities.drop: ["ALL"]` - excess Linux capabilities
- Missing CPU/memory limits - resource exhaustion attacks

**2 WARNINGS:**

- Missing liveness/readiness probes - operational issue

### 2. Hardened Manifest Fixes

**All 30 tests passed** with these security improvements:

- **Image**: Fixed version (`v19.0.0`) instead of `:latest`
- **SecurityContext**: `runAsNonRoot: true`, `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`, `capabilities.drop: ["ALL"]`
- **Resources**: CPU/memory requests & limits defined
- **Probes**: Liveness & readiness checks added

### 3. Docker Compose Results

**15 tests passed** - Compose manifest meets all security policies:

- Non-root user, read-only FS, dropped capabilities, no-new-privilege

