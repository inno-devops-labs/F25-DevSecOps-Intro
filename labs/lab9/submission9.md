# Task 1 — Runtime Security Detection with Falco

## Baseline alerts observed from **falco.log**

Baseline alerts:
- **Critical** - 3 occasions:
    1. **Detect release_agent File Container Escapes** - an attempt to exploit the escape vulnerability of the container
    2. **Fileless execution via memfd_create** - file-free execution via memfd
    3. **Drop and execute new binary in container** - executing a new binary file in a container

- **Warning**: 15 occasions
    1. **Write Binary Under UsrLocalBin** - writing a file to /usr/local/bin
    2. **Create Symlink Over Sensitive Files** - creating symlinks to sensitive files
    3. **Find AWS Credentials** - AWS credentials search
    4. **Remove Bulk Data from Disk** - deleting data from a disk
    5. **Search Private Keys or Passwords** - search for private keys
    6. **Clear Log Activities** - clearing logs
    7. **Read sensitive file trusted after startup** - reading sensitive files
    8. **Netcat Remote Code Execution in Container** - running netcat with RCE
    9. **Execution from /dev/shm** - execution from /dev/shm
    10. **Debugfs Launched in Privileged Container** - running debugfs
    11. **Directory traversal monitored file read** - reading files through directory traversal
    12. **Create Hardlink Over Sensitive Files** - creating hardlinks
    13. **PTRACE attached to process** - attaching ptrace to a process

- **Notice** - 4 occasions:
    1. **Terminal shell in container** - launching a shell in a container
    2. **Run shell untrusted** - running shell with an unreliable binary
    3. **Packet socket created in container** - creating a packet socket
    4. **Disallowed SSH Connection Non Standard Port** - SSH connection to a non-standard port

- **Informational** - 1 occasion:
    1. **System user interactive** - the system user has run an interactive command

## Custom rule’s purpose and when it should/shouldn’t fire

**Rule:** "Write Binary Under UsrLocalBin"

**Purpose:** Detecting file entries in the /usr/local/bin directory, which may indicate:

- Installing unauthorized software
- An attempt at persistence in the system
- Downloading malicious binary files

**When should it work:**

- When writing any files to /usr/local/bin
- In containers and on hosts
- For all users, including root

**When it shouldn't work:**

- During legitimate software installation operations
- When using trusted system package managers
- In CI/CD pipelines with authorized dependency installation

---

# Task 2 — Policy-as-Code with Conftest (Rego)

## The policy violations from the unhardened manifest and why each matters for security

- Latest Tag Usage
- Missing SecurityContext
- No Resource Limits
- Missing Liveness/Readiness Probes
- No Non-Root Execution
- Writable Root Filesystem
- Excessive Capabilities

## The specific hardening changes in the hardened manifest that satisfy policies

- Image Security Hardening
- Privilege Reduction
- Privilege Escalation Prevention
- Filesystem Hardening
- Linux Capabilities Dropping
- Resource Management
- Application Health Monitoring

## Analysis of the Docker Compose manifest results

**Unhardened manifest**:

- **FAIL** - 8 occasions:
    1. **Missing CPU limits** - Risk of resource exhaustion attacks
    2. **Missing memory limits** - Potential for memory-based DoS
    3. **Missing CPU requests** - Poor cluster scheduling
    4. **Missing memory requests** - Unpredictable resource allocation
    5. **Privilege escalation allowed** - Container escape vulnerability
    6. **Writable root filesystem** - Malware persistence risk
    7. **Running as root** - Privilege escalation to host
    8. **Latest tag usage** - Supply chain unpredictability

- **WARN** - 2 occasions:
    1. **Missing livenessProbe** - No automatic recovery from failures
    2. **Missing readinessProbe** - Potential service degradation

**Hardened manifest**:

All Security Controls Implemented