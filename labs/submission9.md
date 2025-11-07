# Task 1

### Baseline alerts:

From task 1.3, only the shell spawning was detected; creating a file under /usr/local/bin was not.

After adding the custom rule, it was detected.

`falco.log` got polluted; see `diff falco.log falco-clean.log` in `labs/lab9/falco/logs`. Here are all the rules
triggered (extracted with `jq .rule falco-clean.log`):

- "Terminal shell in container"
- "Write Binary Under UsrLocalBin" (**this is custom**)
- "Netcat Remote Code Execution in Container"
- "Detect release_agent File Container Escapes"
- "Search Private Keys or Passwords"
- "Debugfs Launched in Privileged Container"
- "Remove Bulk Data from Disk"
- "Packet socket created in container"
- "Directory traversal monitored file read"
- "Create Hardlink Over Sensitive Files"
- "PTRACE attached to process"
- "Drop and execute new binary in container"
- "Read sensitive file trusted after startup"
- "System user interactive"
- "Find AWS Credentials"
- "Clear Log Activities"
- "PTRACE anti-debug attempt"
- "Create Symlink Over Sensitive Files"
- "Disallowed SSH Connection Non Standard Port"
- "Fileless execution via memfd_create"
- "Read sensitive file untrusted"
- "Execution from /dev/shm"
- "Execution from /dev/shm"
- "Run shell untrusted"

# Task 2

## Violations
- **(WARN) container "juice" should define livenessProbe**: kubernetes will restart the failed container, the system
becomes more failure-resistant.
- **(WARN) container "juice" should define readinessProbe**: kubernetes will know if a container failed to start.
- **(FAIL) container "juice" missing resources.limits.cpu**: prevents intruders from gaining cpu resources.
- **(FAIL) container "juice" missing resources.limits.memory**: prevents DOS of other containers by taking all memory.
- **(FAIL) container "juice" missing resources.requests.cpu**: allows kubernetes to make smarter decisions on where to
run the container; sets the minimal guaranteed CPU that the container gets. Helps with stability.
- **(FAIL) container "juice" missing resources.requests.memory**: allows kubernetes to make smarter decisions on where to
run the container; sets the minimal guaranteed memory that the container gets. Helps with stability.
- **(FAIL) container "juice" must set allowPrivilegeEscalation: false**: prevents pivilege-escalation attacks.
- **(FAIL) container "juice" must set readOnlyRootFilesystem: true**: prevents 'container drift'.
- **(FAIL) container "juice" must set runAsNonRoot: true**: prevents unauthorized access (following principle of least
privilege).
- **(FAIL) container "juice" uses disallowed :latest tag**: prevents supply chain attacks by fixing the image version.

## Hardening changes

- Fix the image version to v19.0.0
- Set `runAsNonRoot`
- Reset `allowPrivilegeEscalation`
- Set `readOnlyRootFilesystem`
- Drop all capabilities
- Set reasonable minimal resouces (CPU to 0.1 CPU, memory to 256MiB)
- Limit available resources (CPU to 0.5 CPU, memory to 512MiB)
- Set up a readiness prober
- Set up a periodic liveness prober:

## Docker compose analysis

No issues were found in the docker-compose configuration.
