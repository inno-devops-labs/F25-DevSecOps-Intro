# Lab 9 — Monitoring & Compliance: Falco Runtime Detection + Conftest Policies

## Task 1 — Runtime Security Detection with Falco

### Baseline alerts observed from falco.log

1. **Terminal shell in container** 

   - Severity: NOTICE
   - Event detected when a shell session was started inside a container. 
   - Indicates potential unauthorized container access.

2. **Write Binary Under UsrLocalBin**

   - Severity: WARNING 

   - Event detected when a file `/usr/local/bin/custom-rule.txt` was created inside the container `lab9-helper` as user `root`.  

   - Falco output: 

     ```
     2025-11-07T18:13:45.806115586+0000: Warning Falco Custom: File write in /usr/local/bin (container=lab9-helper user=root file=/usr/local/bin/custom-rule.txt)
     ```

   - Shows compliance drift and potential unauthorized binary writes in critical directories.

### Custom rule’s purpose and when it should/shouldn’t fire

- The custom Falco rule **detects file writes under `/usr/local/bin`**.  
- It should fire whenever a process (especially running as root) writes to `/usr/local/bin`, highlighting a security-sensitive operation.  
- It should **not fire** for legitimate package manager installations or container image builds where such writes are expected and controlled.

---

## Task 2 — Policy-as-Code with Conftest (Rego)

### The policy violations from the unhardened manifest and why each matters for security

The `juice-unhardened.yaml` deployment failed the following security checks:

| Failure                                     | Description                                                  |
| ------------------------------------------- | ------------------------------------------------------------ |
| uses disallowed `:latest` tag               | Container image uses `bkimminich/juice-shop:latest`, which prevents reproducible deployments. |
| must set `runAsNonRoot: true`               | The container runs as root, increasing risk of privilege escalation. |
| must set `allowPrivilegeEscalation: false`  | Privilege escalation is allowed, violating the security baseline. |
| must set `readOnlyRootFilesystem: true`     | Writable root filesystem increases risk if the container is compromised. |
| must drop ALL capabilities                  | Container retains default Linux capabilities, increasing attack surface. |
| missing `resources.requests.cpu` / `memory` | No CPU/memory requests can lead to resource starvation or unbalanced scheduling. |
| missing `resources.limits.cpu` / `memory`   | No CPU/memory limits can allow a container to monopolize node resources. |
| should define readiness/liveness probes     | Missing probes reduce reliability and observability of container health. |

### The specific hardening changes in the hardened manifest that satisfy policies

The `juice-hardened.yaml` deployment addresses all policy violations:

- Image pinned to version `v19.0.0` (no `:latest` tag).  
- `securityContext`:
  - `runAsNonRoot: true`
  - `allowPrivilegeEscalation: false`
  - `readOnlyRootFilesystem: true`
  - `capabilities.drop: ["ALL"]`
- Resource management:
  - `requests: cpu=100m, memory=256Mi`
  - `limits: cpu=500m, memory=512Mi`
- Health probes:
  - `readinessProbe` and `livenessProbe` configured with appropriate paths and delays.

### Analysis of the Docker Compose manifest results

- `juice-compose.yml` passed all 15 Conftest tests.  
- No policy violations were detected:
  - Non-root user configured  
  - Read-only filesystem enforced  
  - All capabilities dropped  
  - Recommended `no-new-privileges` security option set  
