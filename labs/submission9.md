# Lab 9 — Submission

## Task 1 - Falco Runtime Detection

### Baseline Alerts (evidence)
- **Terminal shell in container** at `2025-11-07T18:16:23.209907608Z` | user=root | proc=sh | cmd=`sh -lc echo hello-from-shell` | file=``

### Custom Rule and Evidence
**Rule name:** `Write Binary Under UsrLocalBin`  
**Intent:** Alert on writes inside `/usr/local/bin` in any container (drift detection).  
**Why it helps:** Writing under binary directories is a strong indicator of image drift or persistence attempts.  

Evidence (first two hits parsed):
- **Write Binary Under UsrLocalBin** at `2025-11-07T18:16:34.172443196Z` | user=root | proc=None | cmd=`None` | file=`/usr/local/bin/drift.txt`
- **Write Binary Under UsrLocalBin** at `2025-11-07T18:16:50.778228010Z` | user=root | proc=None | cmd=`None` | file=`/usr/local/bin/custom-rule.txt`

### Custom Rule Source
```yaml
# labs/lab9/falco/rules/custom-rules.yaml
# Detect new writable files under /usr/local/bin inside any container
- rule: Write Binary Under UsrLocalBin
  desc: Detects writes under /usr/local/bin inside any container
  condition: (evt.type in (open, openat, openat2, creat)) and
             (evt.is_open_write=true) and
             (fd.name startswith /usr/local/bin/) and
             (container.id != host)
  output: >
    Falco Custom: File write in /usr/local/bin (container=%container.name user=%user.name file=%fd.name flags=%evt.arg.flags)
  priority: WARNING
  tags: [container, compliance, drift]
```

**Counts (entire log):**
- By severity: {'Notice': 5, 'Warning': 15, 'Informational': 1, 'Critical': 3}
- Top rules: {'Write Binary Under UsrLocalBin': 2, 'Execution from /dev/shm': 2, 'Terminal shell in container': 1, 'System user interactive': 1, 'Search Private Keys or Passwords': 1}

---

## Task 2 - Policy-as-Code with Conftest (OPA/Rego)

### Unhardened Kubernetes Manifest - Violations (why each matters)
- Missing CPU/memory *requests* and *limits* (DoS/Noisy Neighbor control; scheduler guarantees).
- No `allowPrivilegeEscalation: false` (prevents gaining extra Linux capabilities via setuid binaries).
- `readOnlyRootFilesystem: false` (tamper resistance; blocks self-modification and credential drops).
- Not `runAsNonRoot` (limits impact of compromise).
- Image uses `:latest` tag (non-repeatable, risk of unexpected changes).
- Probes (liveness/readiness) are missing (resiliency/auto-heal readiness).

### Hardened Kubernetes Manifest - Fixes Applied
- Pinned image tag `bkimminich/juice-shop:v19.0.0`.
- SecurityContext: `runAsNonRoot: true`, `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`, `capabilities.drop: ["ALL"]`.
- Resource `requests`/`limits` added.
- Readiness & liveness HTTP probes.
- Service exposes port 80 to container 3000.

### Docker Compose Manifest - Results
- Runs as non-root `user: "10001:10001"`.
- `read_only: true`, temp storage isolated via `tmpfs: ["/tmp"]`.
- `no-new-privileges:true` and `cap_drop: ["ALL"]` set.
- Ports mapped `3006:3000`.
