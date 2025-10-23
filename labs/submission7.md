## Prerequisites

**Verify installation:**
```bash
docker scout version


      ⢀⢀⢀             ⣀⣀⡤⣔⢖⣖⢽⢝
   ⡠⡢⡣⡣⡣⡣⡣⡣⡢⡀    ⢀⣠⢴⡲⣫⡺⣜⢞⢮⡳⡵⡹⡅
  ⡜⡜⡜⡜⡜⡜⠜⠈⠈        ⠁⠙⠮⣺⡪⡯⣺⡪⡯⣺ 
 ⢘⢜⢜⢜⢜⠜               ⠈⠪⡳⡵⣹⡪⠇ 
 ⠨⡪⡪⡪⠂    ⢀⡤⣖⢽⡹⣝⡝⣖⢤⡀    ⠘⢝⢮⡚       _____                 _   
  ⠱⡱⠁    ⡴⡫⣞⢮⡳⣝⢮⡺⣪⡳⣝⢦    ⠘⡵⠁      / ____| Docker        | |  
   ⠁    ⣸⢝⣕⢗⡵⣝⢮⡳⣝⢮⡺⣪⡳⣣    ⠁      | (___   ___ ___  _   _| |_ 
        ⣗⣝⢮⡳⣝⢮⡳⣝⢮⡳⣝⢮⢮⡳            \___ \ / __/ _ \| | | | __|
   ⢀    ⢱⡳⡵⣹⡪⡳⣝⢮⡳⣝⢮⡳⡣⡏    ⡀       ____) | (_| (_) | |_| | |_ 
  ⢀⢾⠄    ⠫⣞⢮⡺⣝⢮⡳⣝⢮⡳⣝⠝    ⢠⢣⢂     |_____/ \___\___/ \__,_|\__|
  ⡼⣕⢗⡄    ⠈⠓⠝⢮⡳⣝⠮⠳⠙     ⢠⢢⢣⢣  
 ⢰⡫⡮⡳⣝⢦⡀              ⢀⢔⢕⢕⢕⢕⠅ 
 ⡯⣎⢯⡺⣪⡳⣝⢖⣄⣀        ⡀⡠⡢⡣⡣⡣⡣⡣⡃  
⢸⢝⢮⡳⣝⢮⡺⣪⡳⠕⠗⠉⠁    ⠘⠜⡜⡜⡜⡜⡜⡜⠜⠈   
⡯⡳⠳⠝⠊⠓⠉             ⠈⠈⠈⠈      



version: v1.18.4 (go1.24.6 - darwin/arm64)
git commit: fc5a36b0a880177e9222ead7199a4fbc43cf7184
```

## Task 1 — Image Vulnerability & Configuration Analysis

### Top 5 Critical/High Vulnerabilities

1. **vm2 (Critical — Remote Code Execution)**
   - **Affected Package:** `vm2@3.9.17`
   - **Severity:** Critical
   - **Impact:** Multiple RCE vulnerabilities allowing attackers to escape the sandbox and execute arbitrary code on the host.

2. **marsdb (Critical — Arbitrary Code Injection)**
   - **Affected Package:** `marsdb@0.6.11`
   - **Severity:** Critical
   - **Impact:** Enables arbitrary code injection through specially crafted queries.

3. **multer (Critical — Denial of Service)**
   - **Affected Package:** `multer@1.4.5-lts.2`
   - **Severity:** Critical
   - **Impact:** Uncaught exceptions may lead to application crashes and denial of service.

4. **express-jwt (High — Authorization Bypass)**
   - **Affected Package:** `express-jwt@0.1.3`
   - **Severity:** High
   - **Impact:** Flaws in token validation may allow unauthorized access to protected resources.

5. **jsonwebtoken (High — Authentication Bypass)**
   - **Affected Package:** `jsonwebtoken@0.4.0`
   - **Severity:** High
   - **Impact:** Weak JWT verification allows attackers to bypass authentication mechanisms.

---

### Dockle Configuration Findings

**FATAL Issues:**  
- None detected ✅  

**WARN Issues:**

1. **DKL-LI-0001 — Avoid Empty Passwords** *(Skipped)*
   - **Risk:** Could permit unauthorized access if password authentication is enabled.

2. **CIS-DI-0005 — Enable Docker Content Trust** *(Info)*
   - **Risk:** Without content trust, images might be tampered with during distribution.

3. **CIS-DI-0006 — Add HEALTHCHECK Instruction** *(Info)*
   - **Risk:** Missing health checks reduce observability and hinder orchestration.

4. **DKL-LI-0003 — Include Only Necessary Files** *(Info)*
   - **Risk:** Unnecessary files (e.g., `.DS_Store`) may expose metadata or increase the attack surface.

---

### Security Posture Assessment

**Container User:**  
Dockle results do not explicitly confirm user privileges. However, system file detections suggest possible root-level access — **further verification required**.

---

### Security Improvement Recommendations

#### Immediate Actions (Critical/High Severity)

1. **Upgrade Vulnerable Dependencies**
   - `vm2` → ≥ 3.9.18  
   - `marsdb` → replace with a maintained alternative  
   - `multer` → ≥ 2.0.2  
   - `express-jwt` → ≥ 6.0.0  
   - `jsonwebtoken` → ≥ 5.0.0  

2. **Replace Deprecated/Unpatched Packages**
   - Replace `express-ipfilter` and `libxmljs2` with maintained, secure alternatives.  
   - Remove or substitute `juicy-chat-bot` if security patches are unavailable.

---

### Container Hardening Recommendations

1. **Run as a Non-Root User**
```dockerfile
   USER node 
```
2. **Add Health Checks**
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1
```

3. **Enable Docker Content Trust**
```dockerfile
export DOCKER_CONTENT_TRUST=1
```



## **Task 2 — Docker Host Security Benchmarking**

### **Summary**

**Overall Score:** 11/100 — ❌ *Poor Security Posture*

**Scan Results:**
- ✅ **PASS:** 14  
- ⚠️ **WARN:** 23  
- ❌ **FAIL:** 0  
- ℹ️ **INFO:** 37  

---

### **High-Priority Findings & Recommended Remediation**

1. **Lack of Container-User Isolation** *(WARN 2.8)*  
   - **Risk:** Containers running as root can access the host with root privileges.  
   - **Fix:** Enable user namespace remapping to isolate container users from the host.  

2. **No Docker Auditing Configured** *(WARN 1.5–1.10)*  
   - **Risk:** Security-related Docker events (e.g., container creation, image pulls) are not logged.  
   - **Fix:** Implement `auditd` rules for Docker activities.  

3. **Unrestricted Inter-Container Networking** *(WARN 2.1)*  
   - **Risk:** Compromised containers may communicate laterally with others.  
   - **Fix:** Disable inter-container communication by setting `"icc": false` in `daemon.json`.  

4. **Missing Health Checks** *(WARN 4.6)*  
   - **Risk:** Docker cannot detect or automatically handle unhealthy containers.  
   - **Fix:** Add a `HEALTHCHECK` instruction to all Dockerfiles.  

5. **Image Trust Not Enforced** *(WARN 4.5)*  
   - **Risk:** Potential for running tampered or unverified images.  
   - **Fix:** Enable Docker Content Trust (`DOCKER_CONTENT_TRUST=1`) to ensure image integrity.  

---

### **Quick Remediation Steps**

```bash
# 1. Create a secure Docker daemon configuration
sudo tee /etc/docker/daemon.json > /dev/null << 'EOF'
{
  "icc": false,
  "live-restore": true,
  "no-new-privileges": true
}
EOF

# 2. Remove unused images to reduce attack surface
docker image prune -a

# 3. Enable Docker Content Trust for image verification
export DOCKER_CONTENT_TRUST=1
## **Task 3 — Deployment Security Configuration Analysis**
```
---

### **1. Configuration Comparison Table**

| **Security Measure** | **Default Profile** | **Hardened Profile** | **Production Profile** |
|-----------------------|--------------------|----------------------|-------------------------|
| **Capabilities** | All enabled | `--cap-drop=ALL --cap-add=NET_BIND_SERVICE` | `--cap-drop=ALL --cap-add=NET_BIND_SERVICE` |
| **Security Options** | None | `--security-opt=no-new-privileges` | `--security-opt=no-new-privileges` |
| **Memory Limit** | Unlimited | 512 MB | 512 MB |
| **CPU Limit** | Unlimited | Unlimited | 1 CPU |
| **PID Limit** | Unlimited | Unlimited | 100 PIDs |
| **Restart Policy** | Never | Never | `on-failure:3` |
| **Functionality Test** | ✅ HTTP 200 | ✅ HTTP 200 | ❌ HTTP 000 |

---

### **2. Security Measure Analysis**

#### **a) Linux Capabilities**

**What are Linux capabilities?**  
They divide root privileges into smaller, fine-grained permissions.  
Example: `NET_BIND_SERVICE` allows binding to ports < 1024 without full root access.

**Attack vector mitigated by `--cap-drop=ALL`:**  
- Prevents container escape to host root privileges.  
- Even if compromised, the container cannot alter system files or load kernel modules.

**Why re-add `NET_BIND_SERVICE`:**  
- Needed for web servers (e.g., binding to ports 80/443).  
- Without it, Juice Shop cannot serve HTTP traffic.  

**Security trade-off:**  
- Only one minimal capability is restored — a far smaller risk than running with all root privileges.

---

#### **b) `--security-opt=no-new-privileges`**

**Purpose:**  
Prevents any process inside the container from gaining additional privileges during execution.  

**Attacks prevented:**  
- Privilege escalation via SUID binaries or `execve()` calls.  
- Blocks exploitation paths where a low-privileged user elevates to root.  

**Potential downsides:**  
- Certain legitimate tools requiring privilege escalation may fail.  
- Some monitoring or security agents might need adjustments.

---

#### **c) `--memory=512m` and `--cpus=1.0`**

**Without limits:**  
A container can consume unlimited system resources, leading to host-level Denial of Service (DoS).  

**Threats mitigated:**  
- Memory exhaustion (system freeze).  
- CPU saturation impacting other workloads.  

**Risks of overly tight limits:**  
- Crashes under normal traffic spikes.  
- Reduced performance or failed deployments.  

---

#### **d) `--pids-limit=100`**

**What is a fork bomb?**  
A self-replicating process (e.g., `:(){ :|:& };:`) that spawns infinitely, exhausting all PIDs.

**How PID limiting helps:**  
- Containment: the fork bomb stays inside the container.  
- Protects the host from process table exhaustion.

**Tuning guidance:**  
- Observe normal process usage under load.  
- Add ~20–30% buffer.  
- `100` is sufficient for lightweight web applications.

---

#### **e) `--restart=on-failure:3`**

**What it does:**  
Automatically restarts containers that exit with non-zero status (up to 3 times).

**Benefits:**  
- Recovers from transient errors automatically.  
- Improves service resilience and uptime.

**Cautions:**  
- Can mask underlying instability or security flaws.  
- Safer than `always` since it won’t restart manually stopped containers or enter infinite loops.

---

### **3. Critical Thinking & Observations**

**Development Profile (Default)**  
- **Reasoning:** All privileges enabled for ease of debugging.  
- **Trade-off:** Simplifies troubleshooting but exposes the environment to high risk.

**Hardened Profile (Recommended Baseline)**  
- **Reasoning:** Applies key restrictions without breaking functionality.  
- **Result:** Maintains usability with significantly improved security.

**Production Profile (Over-restricted)**  
- **Issue:** Service failed (HTTP 000), likely due to overly strict PID or CPU limits.  
- **Lesson:** Over-hardening can harm availability — balance is essential.

---

### **Real-World Security Value of Resource Limits**

- Prevents any single container from exhausting host resources.  
- Guarantees predictable performance in shared or multi-tenant environments.  
- Reduces blast radius in case of compromised or malfunctioning services.

---

### **Attacker Capabilities: Default vs. Hardened/Production**

In the hardened or production setup, an attacker **cannot**:
- Escalate to root on the host (capabilities dropped).  
- Launch fork bombs that affect the host (PID limit).  
- Exhaust system resources (memory/CPU limits).  
- Escalate privileges at runtime (`no-new-privileges`).

---

### **Additional Hardening Recommendations**

- Use a **non-root user** inside the container.  
- Set a **read-only root filesystem** (`--read-only`).  
- Apply **Seccomp/AppArmor** or **SELinux** policies.  
- Implement **network policies** restricting egress/ingress.  
- Schedule **regular vulnerability scans** and dependency updates.
