## Task 1

### Alerts observed by Falco:
- Critical Fileless execution via memfd_create
- Critical Executing binary not part of base image 
- Critical Detect an attempt to exploit a container escape using release_agent file

### Custom rule’s purpose and when it should/shouldn’t fire

- It detects writing in /usr/local/bin. Only actions: `open, openat, openat2, creat` when file opened only to write (evt.is_open_write=true)
- It triggered only in container `container.id != host`

## Task 2

The policy violations from the unhardened manifest and why each matters for security
- `runAsNonRoot: true` – Tamper protection. If an attacker penetrates the container, they won't have root privileges to cause serious damage.

- `allowPrivilegeEscalation: false` – Blocks a key attack vector. Prevents a process from escalating its privileges, even if it's vulnerable.

- `readOnlyRootFilesystem: true` – Modification protection. An attacker won't be able to write malicious files or modify system files inside the container.

- `capabilities:drop:["ALL"]` – Vulnerability minimization. Removes all unnecessary privileges from the container, leaving only the bare minimum required for operation.

The specific hardening changes in the hardened manifest that satisfy policies
- `runAsNonRoot` - grants, that container will be run not as root user.
- `allowPrivilegeEscalation:false`- prohibit process grant higher priviliges.
- `readOnlyRootFilesystem` - mount root file system `/` to read only.
- `capabilities: drop: ["ALL"]` - delete all default Linux Capabilities.
- `requests: { cpu: "100m", memory: "256Mi" }` - k8s will allocate at least 1 core of cpu and 256 mb ram.
- `limits: { cpu: "500m", memory: "512Mi" }` - limits container resources. 
- `readinessProbe` - Checks whether the application is ready to receive traffic.
- `livenessProbe` - Checks whether the application is still alive. Not just whether the process is running, but whether it is functioning properly.

Analysis of the Docker Compose manifest results

- Container cannot run as root user.
- Read only root file system
- Reset all linux capabillities.