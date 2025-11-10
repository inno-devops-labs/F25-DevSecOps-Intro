# Lab 7 — Container Security: Image Scanning & Deployment Hardening

## Task 1 — Image Vulnerability & Configuration Analysis

### Top 5 Critical/High Vulnerabilities

**1. CVE in vm2 (Critical - Remote Code Execution)**

- **Affected Package**: vm2@3.9.17
- **Severity**: Critical
- **Impact**: Multiple RCE vulnerabilities allowing attackers to break out of the sandbox and execute arbitrary code on the host system

**2. CVE in marsdb (Critical - Arbitrary Code Injection)**

- **Affected Package**: marsdb@0.6.11
- **Severity**: Critical
- **Impact**: Allows arbitrary code injection through specially crafted queries

**3. CVE in multer (Critical - Uncaught Exception)**

- **Affected Package**: multer@1.4.5-lts.2
- **Severity**: Critical
- **Impact**: Uncaught exceptions leading to denial of service

**4. CVE in express-jwt (High - Authorization Bypass)**

- **Affected Package**: express-jwt@0.1.3
- **Severity**: High
- **Impact**: Authorization bypass allowing unauthorized access to protected resources

**5. CVE in jsonwebtoken (High - Authentication Bypass)**

- **Affected Package**: jsonwebtoken@0.4.0
- **Severity**: High
- **Impact**: Authentication bypass vulnerabilities in JWT verification

### Dockle Configuration Findings

**FATAL Issues:**

- No fatal issues detected

**WARN Issues:**

1. **DKL-LI-0001: Avoid empty password** (Skipped)

    - **Security Concern**: Could allow unauthorized access if password authentication is used

2. **CIS-DI-0005: Enable Content trust for Docker** (Info)

    - **Security Concern**: Without content trust, images could be tampered with during distribution

3. **CIS-DI-0006: Add HEALTHCHECK instruction** (Info)

    - **Security Concern**: Lack of health checks makes container orchestration and monitoring less effective

4. **DKL-LI-0003: Only put necessary files** (Info)

    - **Security Concern**: Unnecessary files (.DS_Store) in node_modules increase attack surface and may contain sensitive metadata

### Security Posture Assessment

**Does the image run as root?**

The Dockle results don't explicitly show user configuration, but the presence of system files detection suggests the container may have root-like access. Further investigation needed.


### Security Improvement Recommendations

#### Immediate Actions (Critical/High Severity):

1. **Upgrade Vulnerable Dependencies**:

    - Upgrade `vm2` to latest version (≥3.9.18 if available)
    - Replace `marsdb` with a maintained alternative
    - Upgrade `multer` to 2.0.2+
    - Upgrade `express-jwt` to 6.0.0+
    - Upgrade `jsonwebtoken` to 5.0.0+

2. **Address Unpatchable Vulnerabilities**:

    - Replace `express-ipfilter` with a maintained alternative
    - Replace `libxmljs2` with a secure alternative
    - Remove or replace `juicy-chat-bot` if possible

### Container Hardening:

1. **Implement Non-root User**:
    
    ```dockerfile
    USER node  # or create a dedicated non-root user
    ```
    
2. **Add Health Checks**:
    
    ```dockerfile
    HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
      CMD curl -f http://localhost:3000/ || exit 1
	```
    
3. **Enable Content Trust**:
    
    ```bash
    export DOCKER_CONTENT_TRUST=1
    ```

## Task 2 — Docker Host Security Benchmarking

### Summary

**Score: 11/100 - Poor Security**

**Results:**

- PASS: 14
- WARN: 23
- FAIL: 0
- INFO: 37

### Critical Failures & Remediation

### High Priority Issues:

1. **No container-user isolation** (WARN 2.8)

    - _Risk:_ Container root = host root
    - _Fix:_ Enable user namespace remapping

2. **No Docker auditing** (WARN 1.5-1.10)

    - _Risk:_ No security event tracking
    - _Fix:_ Implement auditd rules for Docker

3. **Unrestricted inter-container network** (WARN 2.1)

    - _Risk:_ Lateral movement if compromised
    - _Fix:_ Set `"icc": false` in daemon.json

4. **No health checks** (WARN 4.6)

    - _Risk:_ Can't detect unhealthy containers
    - _Fix:_ Add HEALTHCHECK to all Dockerfiles

5. **No image trust** (WARN 4.5)

    - _Risk:_ Running tampered images
    - _Fix:_ Enable DOCKER_CONTENT_TRUST=1

## Quick Fixes

```bash
# 1. Create secure daemon config
sudo cat > /etc/docker/daemon.json << EOF
{
  "icc": false,
  "live-restore": true,
  "no-new-privileges": true
}
EOF

# 2. Clean up images
docker image prune -a

# 3. Enable content trust
export DOCKER_CONTENT_TRUST=1
```

**Priority:** Address user isolation and auditing immediately before production use.

## Task 3 — Deployment Security Configuration Analysis

### 1. Configuration Comparison Table

|Security Measure|Default Profile|Hardened Profile|Production Profile|
|---|---|---|---|
|**Capabilities**|All enabled|`--cap-drop=ALL --cap-add=NET_BIND_SERVICE`|`--cap-drop=ALL --cap-add=NET_BIND_SERVICE`|
|**Security Options**|None|`no-new-privileges`|`no-new-privileges`|
|**Memory Limit**|Unlimited|512MB|512MB|
|**CPU Limit**|Unlimited|Unlimited|1.0 CPU|
|**PID Limit**|Unlimited|Unlimited|100 PIDs|
|**Restart Policy**|Never|Never|`on-failure:3`|
|**Functionality**|✅ HTTP 200|✅ HTTP 200|❌ HTTP 000|

### 2. Security Measure Analysis

#### a) Linux Capabilities

**What are Linux capabilities?**

- Fine-grained privileges that split root power into distinct units
- Example: `NET_BIND_SERVICE` allows binding to ports <1024 without full root

**Attack vector prevented by `--cap-drop=ALL`:**

- Container escape to host root privileges
- Even if compromised, container can't modify system files, load kernel modules, etc.

**Why add back `NET_BIND_SERVICE`:**

- Web servers need to bind to port 80/443
- Without it, juice-shop can't serve HTTP traffic

**Security trade-off:**

- Minimal privilege loss (only one capability added back)
- Much safer than running with full root capabilities

#### b) `--security-opt=no-new-privileges`

**What it does:**

- Prevents processes from gaining higher privileges during execution
- Blocks `setuid` binaries from escalating privileges

**Attack prevented:**

- Privilege escalation via SUID binaries or execve with elevated privileges
- Stops chain: user → root via vulnerable SUID program

**Downsides:**

- May break legitimate applications that need privilege escalation
- Some monitoring tools or security software might require privilege changes

#### c) `--memory=512m` and `--cpus=1.0`

**Without limits:**

- Container can consume all host memory/CPU causing system-wide DoS
- "Noisy neighbor" problem affects other containers/apps

**Attack prevented:**

- Memory exhaustion attacks (making system unresponsive)
- CPU saturation attacks

**Risk of low limits:**

- Application crashes under normal load
- Poor performance during traffic spikes

#### d) `--pids-limit=100`

**What is a fork bomb?**

- Malicious code: `:(){ :|:& };:` creates infinite processes
- Consumes all system PIDs, making system unresponsive

**How PID limiting helps:**

- Contains fork bomb to container onl
- Prevents system-wide process table exhaustion

**Determining the right limit:**

- Monitor normal process count under load
- Add 20-30% buffer for spikes
- 100 is reasonable for simple web apps

#### e) `--restart=on-failure:3`

**What it does:**

- Auto-restarts container if it exits with non-zero status
- Maximum 3 restart attempts, then gives up

**Beneficial for:**

- Recovering from transient failures
- Maintaining service availability

**Risky when:**

- Restarting crashed vulnerable applications
- Masking underlying stability issues

**vs `always`:**

- `on-failure` won't restart manually stopped containers
- Prevents infinite restart loops for configuration issues

### 3. Critical Thinking Questions

**Development Profile: DEFAULT**

- Why: Full privileges for debugging, no restrictions during development
- Trade-off: Less secure but easier to troubleshoot

**Production Profile: HARDENED** (not Production since it's broken)

- Why: Security measures without breaking functionality
- Production profile failed (HTTP 000) - likely PID limit too restrictive

**Real-world problem resource limits solve:**

- Prevents single container from taking down entire host
- Ensures predictable performance in multi-tenant environments

**Attacker in Default vs Production:**  
In Production, attacker cannot:

- Escalate to root on host (capabilities dropped)
- Fork bomb the system (PID limited)
- Exhaust host memory/CPU (resource limits)
- Gain higher privileges during runtime (no-new-privileges)

**Additional hardening:**

- Read-only root filesystem
- Non-root user inside container
- Seccomp/AppArmor profiles
- Network policies restricting egress
- Regular vulnerability scanning
