# Lab 9

## Task 1

### Evidence (baseline alerts observed)
- Falco observed an interactive shell opened inside the helper container (attached terminal).
- Falco raised a custom WARNING when a process in `lab9-helper` wrote to `/usr/local/bin/drift.txt`.
- A second WARNING recorded a validation write to `/usr/local/bin/custom-rule.txt` (both writes show FD_UPPER_LAYER).

### Custom rule purpose
- Rule: Binary W Under UsrLocalBin
- Purpose: detect creation or modification of files under `/usr/local/bin` inside containers — a common indicator of post-deployment tampering or container drift.

### When the rule should fire
- When any container process opens/creates a file for write under `/usr/local/bin/` (open/openat/openat2/creat with write flags).

### When the rule should NOT fire (tuning guidance)
- Exclude trusted build or management containers (by `container.image.repository` or `container.name`).
- Optionally ignore package-manager writes or root-owned maintenance processes, or lower severity/rate-limit alerts to reduce noise.

### Quick operational notes
- Falco reloads rules from `/etc/falco/rules.d`; if a reload is needed, send SIGHUP to the Falco container.
- Validation steps used: start helper (alpine), spawn shell, perform test writes to `/usr/local/bin` and confirm rule alerts.

### Minimal next steps / recommendations
- Add allowlists for known builders and legitimate images to reduce false positives.
- Map the rule to alerting channels and set an appropriate severity.

## Task 2: Policy-as-Code with Conftest (Rego)

### Policy violations from unhardened manifest
The unhardened manifest fails several critical checks that weaken runtime security:
1. `:latest` image tag — unpinned images are unpredictable and hinder reproducible, auditable deployments.
2. Missing `runAsNonRoot: true` — runs as root, increasing risk of privilege escalation and host compromise.
3. Missing `allowPrivilegeEscalation: false` — allows child processes to gain privileges beyond the parent.
4. Missing `readOnlyRootFilesystem: true` — writable root enables tampering and persistence by attackers.
5. No capability drops — retains unnecessary Linux capabilities that enlarge attack surface.
6. Missing CPU requests/limits — permits CPU exhaustion and noisy-neighbor denial-of-service.
7. Missing memory requests/limits — risk of OOM and node instability.
8. (Warn) Missing readiness/liveness probes — reduces ability to detect and recover unhealthy pods.

### The specific hardening changes in the hardened manifest
The hardened manifest addresses the failures with these concrete changes:
- Image pinning: `bkimminich/juice-shop:v19.0.0` (replaces `:latest`).
- SecurityContext:
  - `runAsNonRoot: true` (avoid root execution)
  - `allowPrivilegeEscalation: false` (prevent privilege gains)
  - `readOnlyRootFilesystem: true` (limit writable surface)
  - `capabilities.drop: ["ALL"]` (remove extra capabilities)
- Resource limits/requests set for CPU and memory (prevents resource exhaustion and noisy neighbors).
- Readiness and liveness probes added (improves availability and automated recovery).

These changes directly satisfy the conftest rules by removing root execution, limiting privileges, pinning images, and enforcing resource and availability controls.

### Analysis of the Docker Compose manifest results
- `conftest-compose.txt` shows all 15 compose checks passed with no denies.
- The compose policy requires non-root user, read-only root filesystem, and `cap_drop: ["ALL"]`; the manifest meets these requirements.
- Recommendation: add `no-new-privileges` and maintain image pinning and resource constraints in compose files where supported.
