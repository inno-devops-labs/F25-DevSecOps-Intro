# Lab 7 - Container Security: Image Scanning & Deployment Hardening

```bash
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
```

## Task 1 — Image Vulnerability & Configuration Analysis

### 1.1 Top 5 Critical/High Vulnerabilities

Based on Docker Scout CVE analysis of `bkimminich/juice-shop:v19.0.0`:

1. **CVE-2023-37903** (CRITICAL, CVSS 9.8) - vm2 3.9.17
   - **Impact**: OS Command Injection vulnerability
   - **Affected Package**: vm2@3.9.17
   - **Risk**: Allows remote code execution through improper neutralization of special elements

2. **CVE-2023-37466** (CRITICAL, CVSS 9.8) - vm2 3.9.17
   - **Impact**: Code Injection vulnerability
   - **Affected Package**: vm2@3.9.17
   - **Risk**: Allows arbitrary code execution through improper control of code generation

3. **CVE-2023-32314** (CRITICAL, CVSS 9.8) - vm2 3.9.17
   - **Impact**: Injection vulnerability
   - **Affected Package**: vm2@3.9.17
   - **Risk**: Allows injection attacks through improper neutralization of special elements

4. **CVE-2019-10744** (CRITICAL, CVSS 9.1) - lodash 2.4.2
   - **Impact**: Prototype Pollution vulnerability
   - **Affected Package**: lodash@2.4.2
   - **Risk**: Allows modification of object prototypes leading to potential code execution

5. **CVE-2023-46233** (CRITICAL, CVSS 9.1) - crypto-js 3.3.0
   - **Impact**: Broken cryptographic algorithm
   - **Affected Package**: crypto-js@3.3.0
   - **Risk**: Weak encryption implementation allowing potential data compromise

### 1.2 Dockle Configuration Findings

**FATAL Issues**: None found
**WARN Issues**: None found
**INFO Issues**:
- **CIS-DI-0005**: Enable Content trust for Docker
  - **Security Concern**: Without content trust, images can be tampered with during transmission
  - **Recommendation**: Set `DOCKER_CONTENT_TRUST=1` before pulling images

- **CIS-DI-0006**: Add HEALTHCHECK instruction
  - **Security Concern**: No health monitoring means containers may run in degraded states
  - **Recommendation**: Add HEALTHCHECK instruction to Dockerfile

- **DKL-LI-0003**: Only put necessary files
  - **Security Concern**: Unnecessary files increase attack surface
  - **Found**: `.DS_Store` files in node_modules
  - **Recommendation**: Use .dockerignore to exclude unnecessary files

### 1.3 Security Posture Assessment

**Root User Analysis**: 
- The image runs as root by default (confirmed by CIS benchmark finding 4.1)
- This is a significant security risk as it provides excessive privileges

**Security Improvements Recommended**:
1. **Create non-root user**: Add a dedicated user in the Dockerfile
2. **Update dependencies**: Upgrade vm2, lodash, crypto-js to patched versions
3. **Enable content trust**: Implement Docker content trust for image integrity
4. **Add health checks**: Implement proper health monitoring
5. **Minimize attack surface**: Remove unnecessary files and packages

## Task 2 — Docker Host Security Benchmarking

### 2.1 Summary Statistics

**CIS Docker Benchmark Results**:
- **Total Checks**: 105
- **PASS**: 11
- **WARN**: 47
- **FAIL**: 0
- **INFO**: 47
- **Score**: 11/105 (10.5%)

### 2.2 Analysis of Failures

**Critical Security Issues Identified**:

1. **Container Security (Section 5)**:
   - **5.1**: No AppArmor profiles enabled
   - **5.4**: Privileged containers detected (terminal container)
   - **5.10**: No memory limits on containers
   - **5.11**: No CPU limits on containers
   - **5.12**: Root filesystem not read-only
   - **5.25**: Containers not restricted from acquiring privileges
   - **5.28**: No PID limits set

2. **Host Configuration (Section 1)**:
   - **1.1**: No separate partition for containers
   - **1.5-1.9**: Missing audit configuration for Docker components

3. **Daemon Configuration (Section 2)**:
   - **2.1**: Network traffic not restricted between containers
   - **2.8**: User namespace support not enabled
   - **2.11**: No authorization for Docker client commands
   - **2.12**: No centralized logging configured
   - **2.14**: Live restore not enabled
   - **2.15**: Userland proxy not disabled
   - **2.18**: Containers not restricted from acquiring privileges

### 2.3 Remediation Steps

**Immediate Actions**:
1. **Enable audit logging**: Configure auditd for Docker daemon and files
2. **Implement resource limits**: Set memory, CPU, and PID limits for all containers
3. **Enable security profiles**: Implement AppArmor or SELinux profiles
4. **Restrict privileges**: Use `--cap-drop=ALL` and `--security-opt=no-new-privileges`
5. **Enable user namespaces**: Configure user namespace mapping
6. **Implement network policies**: Restrict inter-container communication
7. **Configure centralized logging**: Set up log aggregation and monitoring

## Task 3 — Deployment Security Configuration Analysis

### 3.1 Configuration Comparison Table

| Configuration | Default | Hardened | Production |
|---------------|---------|----------|------------|
| **Capabilities** | All (default) | Dropped: ALL | Dropped: ALL, Added: NET_BIND_SERVICE |
| **Security Options** | None | no-new-privileges | no-new-privileges |
| **Memory Limit** | None | 512MB | 512MB |
| **Memory Swap** | None | None | 512MB |
| **CPU Limit** | None | 1.0 CPU | 1.0 CPU |
| **PID Limit** | None | None | 100 |
| **Restart Policy** | no | no | on-failure:3 |
| **Seccomp Profile** | Default | Default | Default |

### 3.2 Security Measure Analysis

#### a) `--cap-drop=ALL` and `--cap-add=NET_BIND_SERVICE`

**What are Linux capabilities?**
Linux capabilities are fine-grained permissions that allow processes to perform specific privileged operations without running as root. They provide a more secure alternative to full root privileges.

**Attack vector prevention:**
- **Dropping ALL capabilities** prevents containers from performing privileged operations like mounting filesystems, changing system time, or accessing raw network interfaces
- **Prevents privilege escalation** attacks where malicious code tries to gain additional system privileges

**Why NET_BIND_SERVICE is needed:**
- Allows the container to bind to ports below 1024 (privileged ports)
- Essential for web applications that need to bind to port 80/443
- **Security trade-off**: Minimal risk as it only allows binding to specific ports

#### b) `--security-opt=no-new-privileges`

**What it does:**
- Prevents processes inside the container from gaining additional privileges through setuid/setgid binaries
- Blocks privilege escalation through SUID/SGID executables

**Attack prevention:**
- **Prevents privilege escalation** attacks where attackers exploit SUID binaries to gain root access
- **Blocks kernel exploits** that rely on gaining new privileges

**Downsides:**
- May break legitimate applications that rely on SUID binaries
- Some applications may not function correctly if they expect to gain privileges

#### c) `--memory=512m` and `--cpus=1.0`

**Without resource limits:**
- Containers can consume unlimited system resources
- **Memory exhaustion attacks**: Malicious containers can consume all available RAM
- **CPU starvation**: Resource-intensive containers can starve other processes

**Memory limiting benefits:**
- **Prevents DoS attacks** through memory exhaustion
- **Ensures fair resource allocation** across containers
- **Enables predictable performance** in multi-tenant environments

**Risks of low limits:**
- **Application crashes** if legitimate memory needs exceed limits
- **Performance degradation** if limits are too restrictive
- **Service unavailability** during peak usage

#### d) `--pids-limit=100`

**Fork bomb prevention:**
- **Fork bomb** is an attack where a process creates unlimited child processes, exhausting system resources
- **PID limiting** prevents this by restricting the number of processes a container can create

**Determining the right limit:**
- **Analyze application requirements**: Count normal process usage
- **Add safety margin**: Include buffer for legitimate process creation
- **Monitor and adjust**: Start conservative and increase based on monitoring

#### e) `--restart=on-failure:3`

**What it does:**
- Automatically restarts container if it exits with non-zero status
- **Maximum 3 restart attempts** before giving up
- **Exponential backoff** between restart attempts

**Benefits:**
- **High availability**: Automatic recovery from transient failures
- **Fault tolerance**: Handles application crashes gracefully
- **Reduced manual intervention**: Self-healing containers

**Risks:**
- **Infinite restart loops**: If application has persistent issues
- **Resource waste**: Constantly restarting broken containers
- **Masking real problems**: May hide underlying application issues

**Comparison with `always`:**
- **`on-failure`**: Only restarts on errors, not manual stops
- **`always`**: Restarts even after manual stops, which may be unwanted

### 3.3 Critical Thinking Questions

#### 1. Which profile for DEVELOPMENT? Why?

**Answer: Default profile**
- **Reasoning**: Development environments prioritize ease of debugging and flexibility
- **Benefits**: 
  - No resource constraints that might interfere with debugging
  - Full capabilities for development tools and debugging
  - No security restrictions that might block legitimate development activities
- **Trade-off**: Acceptable security risk in isolated development environment

#### 2. Which profile for PRODUCTION? Why?

**Answer: Production profile**
- **Reasoning**: Production environments require maximum security and resource control
- **Benefits**:
  - **Minimal attack surface**: Dropped capabilities and security options
  - **Resource protection**: Memory, CPU, and PID limits prevent resource exhaustion
  - **Fault tolerance**: Automatic restart policy ensures high availability
  - **Process isolation**: PID limits prevent fork bomb attacks
- **Security**: Best protection against container escape and privilege escalation

#### 3. What real-world problem do resource limits solve?

**Multi-tenant security**: In cloud environments, resource limits prevent one tenant's application from affecting others through:
- **Memory exhaustion attacks**: Malicious containers consuming all RAM
- **CPU starvation**: Resource-intensive containers blocking other services
- **Process flooding**: Fork bombs affecting system stability
- **Cost control**: Preventing runaway resource consumption

#### 4. If an attacker exploits Default vs Production, what actions are blocked in Production?

**Default container compromise allows:**
- Full root privileges on host system
- Unlimited resource consumption
- Process creation without limits
- Privilege escalation through SUID binaries
- Access to all system capabilities

**Production container compromise is limited to:**
- Only NET_BIND_SERVICE capability (can only bind to ports)
- Cannot gain additional privileges (no-new-privileges)
- Cannot create unlimited processes (PID limit: 100)
- Cannot consume unlimited memory (512MB limit)
- Cannot starve CPU resources (1.0 CPU limit)
- Cannot escalate privileges through SUID binaries

#### 5. What additional hardening would you add?

**Additional Security Measures:**
1. **Read-only root filesystem**: `--read-only` flag
2. **User namespace mapping**: `--userns=host` or custom mapping
3. **AppArmor/SELinux profiles**: Custom security profiles
4. **Network policies**: Restrict container-to-container communication
5. **Secrets management**: Use Docker secrets or external secret management
6. **Image scanning**: Regular vulnerability scanning in CI/CD
7. **Runtime monitoring**: Container runtime security monitoring
8. **Log aggregation**: Centralized logging and monitoring
9. **Network segmentation**: Isolated network namespaces
10. **Regular updates**: Automated security updates and patches


