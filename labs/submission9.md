# Lab 9 — Monitoring & Compliance: Falco Runtime Detection

## Task 1 — Runtime Security Detection with Falco

### Baseline Alerts Observed from falco.log

#### 1. **Host System False Positives** 
- **25× `Read sensitive file untrusted` alerts** from `gdm-session-wor` process
- **Root cause**: GNOME Display Manager legitimately accessing PAM configuration files (`/etc/shadow`, `/etc/pam.d/*`) for user authentication
- **Impact**: Demonstrates need for rule tuning in desktop environments

#### 2. **Container Security Events** 🔍
**Deliberately Triggered:**
- `Terminal shell in container` - Shell execution in lab9-helper container via `docker exec`
- `Write Binary Under UsrLocalBin` - Custom rule detecting file creation in `/usr/local/bin/`

**Automated Attack Simulations:**
- **Critical**: Fileless execution, binary drops, container escape attempts
- **Warning**: Credential harvesting, log tampering, network reconnaissance
- **Notice**: Suspicious network connections, raw socket creation

### Custom Rule Analysis

#### Rule Trigger Evidence 
```json
"Write Binary Under UsrLocalBin": "File write in /usr/local/bin (container=lab9-helper user=root file=/usr/local/bin/custom-rule.txt)"
```

#### Rule Logic & Scope
**Detection Scope:**
- File writes to `/usr/local/bin/` path within containers only
- Write operations (`openat`, `creat` with write flags)
- Container context filtering (`container.id != host`)

**Security Rationale:**
- Detects unauthorized binary installation in containers
- Identifies configuration drift from base images
- Monitors for malware deployment in writable directories

#### Operational Boundaries
**Triggers When:**
- Container processes modify `/usr/local/bin/` contents
- New executables are created in binary directories
- File system changes indicate potential compromise

**Suppresses When:**
- Host system file operations
- Read-only access patterns
- Operations outside monitored directory scope

### Key Security Insights

1. **Falco Effectiveness**: Successfully detected both benign (shell access) and malicious (event generator) activities
2. **Custom Rule Validation**: Custom detection logic working as designed for container-specific threats
3. **Noise Management**: Host system processes generate false positives requiring tuning
4. **Comprehensive Coverage**: Default ruleset provides broad detection of ATT&CK techniques


## Task 2 — Policy-as-Code with Conftest (Rego)

### Policy Violations Analysis - Unhardened Manifest

**Overall Result**: 30 tests, 20 passed, 2 warnings, 8 failures, 0 exceptions

#### Critical Security Violations (FAIL) 

1. **Missing Resource Limits**
   - `resources.limits.cpu` - Missing CPU limits
   - `resources.limits.memory` - Missing memory limits
   - `resources.requests.cpu` - Missing CPU requests
   - `resources.requests.memory` - Missing memory requests
   - **Security Impact**: Risk of resource exhaustion attacks (DoS), noisy neighbor problems, unpredictable performance

2. **Privilege Escalation Control**
   - `allowPrivilegeEscalation: false` - Not enforced
   - **Security Impact**: Container processes can gain additional privileges via setuid binaries, increasing attack surface

3. **Filesystem Security**
   - `readOnlyRootFilesystem: true` - Not configured
   - **Security Impact**: Writable root filesystem enables malware persistence, configuration tampering, and data manipulation

4. **Root Execution Prevention**
   - `runAsNonRoot: true` - Not enforced
   - **Security Impact**: Running as root increases blast radius if container is compromised

5. **Image Tag Management**
   - Uses disallowed `:latest` tag
   - **Security Impact**: Unpredictable updates, version drift, difficulty in rollbacks and vulnerability tracking

#### Security Warnings (WARN) 

1. **Missing Liveness Probe**
   - `livenessProbe` not defined
   - **Impact**: Kubernetes cannot detect and restart unhealthy containers automatically

2. **Missing Readiness Probe**
   - `readinessProbe` not defined
   - **Impact**: Traffic may be routed to containers not ready to serve requests

### Hardening Changes Analysis - Hardened Manifest

**Overall Result**: 30 tests, 30 passed, 0 warnings, 0 failures, 0 exceptions

#### Security Hardening Implementations 

1. **Resource Management**
   ```yaml
   resources:
     limits:
       cpu: "500m"
       memory: "512Mi"
     requests:
       cpu: "250m"
       memory: "256Mi"
   ```
   - **Security Benefit**: Prevents resource exhaustion, ensures predictable performance

2. **Security Context**
   ```yaml
   securityContext:
     allowPrivilegeEscalation: false
     readOnlyRootFilesystem: true
     runAsNonRoot: true
     runAsUser: 1000
   ```
   - **Security Benefit**: Minimal privilege execution, immutable filesystem, non-root user

3. **Image Versioning**
   - Uses specific version tag instead of `:latest`
   - **Security Benefit**: Reproducible deployments, controlled updates, precise vulnerability management

4. **Health Monitoring**
   ```yaml
   livenessProbe: [...]
   readinessProbe: [...]
   ```
   - **Security Benefit**: Automated health management, service reliability

### Docker Compose Manifest Analysis

**Overall Result**: 15 tests, 15 passed, 0 warnings, 0 failures, 0 exceptions

#### Security Compliance Status 

The Docker Compose manifest successfully passed all security policies, indicating:

- Proper resource constraints implementation
- Security-focused container configuration
- Compliance with Docker-specific security best practices
- Appropriate service definitions without privileged operations

