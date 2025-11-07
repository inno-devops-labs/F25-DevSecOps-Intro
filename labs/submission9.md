# Lab 9 Report — Falco Runtime Detection & Conftest Policy Enforcement

## Task 1 — Runtime Security Detection with Falco

### Baseline Alerts
Falco detected the following baseline suspicious activities:
- **Terminal shell in container**: Triggered by running `/bin/sh` in the BusyBox container.
- **Container drift (write under binary directory)**: Triggered by writing to `/usr/local/bin/drift.txt`.

### Custom Rule
A custom Falco rule was added:
```yaml
- rule: Write Binary Under UsrLocalBin
  desc: Detects writes under /usr/local/bin inside any container
  condition: evt.type in (open, openat, openat2, creat) and evt.is_open_write=true and fd.name startswith /usr/local/bin/ and container.id != host
  output: >
    Falco Custom: File write in /usr/local/bin (container=%container.name user=%user.name file=%fd.name flags=%evt.arg.flags)
  priority: WARNING
  tags: [container, compliance, drift]
```
**Purpose:** Detects any file write under `/usr/local/bin` inside containers, helping to catch drift and unauthorized changes.
**Validation:** Triggered by writing to `/usr/local/bin/custom-rule.txt`.

### Event Generator
Falco event generator was run to produce additional alerts, confirming Falco's detection capabilities for various suspicious syscalls (e.g., fileless execution, sensitive file reads, privilege escalation attempts).

## Task 2 — Policy-as-Code with Conftest

### Unhardened Manifest Results
Conftest detected multiple policy violations in `juice-unhardened.yaml`:
- Missing liveness/readiness probes (WARN)
- Missing resource limits/requests (FAIL)
- Privilege escalation not disabled (FAIL)
- Root filesystem not read-only (FAIL)
- Container not running as non-root (FAIL)
- Uses disallowed `:latest` tag (FAIL)

**Security Impact:** These failures indicate risks such as resource abuse, privilege escalation, and lack of container immutability.

### Hardened Manifest Results
`juice-hardened.yaml` passed all Conftest checks:
- All required security settings and resource limits are present
- No warnings or failures

**Hardening Changes:**
- Added resource limits/requests
- Set `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`, `runAsNonRoot: true`
- Defined liveness/readiness probes
- Avoided `:latest` tag

### Docker Compose Manifest Results
All Conftest tests passed for `juice-compose.yml`, confirming compliance with Compose security policies.

## Artifacts & Evidence
- Falco logs: `labs/lab9/falco/logs/falco.log`
- Custom rule: `labs/lab9/falco/rules/custom-rules.yaml`
- Conftest results: `labs/lab9/analysis/conftest-unhardened.txt`, `conftest-hardened.txt`, `conftest-compose.txt`
