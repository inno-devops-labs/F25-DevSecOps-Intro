# Lab 9 Submission — Falco Runtime Detection & Conftest Policies

## Task 1 — Falco Runtime Detection

- **Runtime setup**: Ran Falco (`falcosecurity/falco:latest`) with modern eBPF against the helper container `lab9-helper` (`alpine:3.19`) and tailed JSON output into `labs/lab9/falco/logs/falco.log`. Mounted custom rules from `labs/lab9/falco/rules`.
- **Baseline alerts**:
  - Interactive shell spawn was captured while execing into the helper container.

```1:1:labs/lab9/falco/logs/falco.log
{"hostname":"a2f8308c0d75","output":"2025-11-07T15:43:29.873137308+0000: Notice A shell was spawned in a container with an attached terminal | evt_type=execve user=root ...","priority":"Notice","rule":"Terminal shell in container",...}
```

  - Writing under `/usr/local/bin` fired the drift-focused custom rule when creating `drift.txt` and `custom-rule.txt`.

```17:18:labs/lab9/falco/logs/falco.log
{"output":"2025-11-07T15:46:54.319108606+0000: Warning Falco Custom: File write in /usr/local/bin (container=lab9-helper user=root file=/usr/local/bin/drift.txt ...","rule":"Write Binary Under UsrLocalBin",...}
{"output":"2025-11-07T15:47:02.792481161+0000: Warning Falco Custom: File write in /usr/local/bin (container=lab9-helper user=root file=/usr/local/bin/custom-rule.txt ...","rule":"Write Binary Under UsrLocalBin",...}
```

- **Custom rule & tuning**: Authored `Write Binary Under UsrLocalBin` to tighten coverage on binary directories while filtering host activity (`container.id != host`) and restricting to write-oriented syscalls, keeping noise low during legitimate read access.

```1:9:labs/lab9/falco/rules/custom-rules.yaml
- rule: Write Binary Under UsrLocalBin
  desc: Detects writes under /usr/local/bin inside any container
  condition: evt.type in (open, openat, openat2, creat) and 
             evt.is_open_write=true and 
             fd.name startswith /usr/local/bin/ and 
             container.id != host
  output: >
    Falco Custom: File write in /usr/local/bin (container=%container.name user=%user.name file=%fd.name flags=%evt.arg.flags)
  priority: WARNING
  tags: [container, compliance, drift]
```

- **Broader coverage validation**: Running `falcosecurity/event-generator` produced additional high-signal detections (e.g., disallowed SSH, release_agent escape attempt, fileless execution via `memfd_create`), confirming Falco’s baseline policies remained active alongside the custom rule.

```19:30:labs/lab9/falco/logs/falco.log
{"output":"2025-11-07T15:47:26.920999248+0000: Notice Disallowed SSH Connection | ...","rule":"Disallowed SSH Connection Non Standard Port",...}
{"output":"2025-11-07T15:47:28.666054669+0000: Critical Detect an attempt to exploit a container escape using release_agent file | ...","rule":"Detect release_agent File Container Escapes",...}
{"output":"2025-11-07T15:47:36.073964693+0000: Critical Fileless execution via memfd_create | ...","rule":"Fileless execution via memfd_create",...}
```

## Task 2 — Policy-as-Code with Conftest (Rego)

### Policy Violations in Unhardened Manifest

Running Conftest against `juice-unhardened.yaml` produced eight failures and two warnings.

```1:12:labs/lab9/analysis/conftest-unhardened.txt
WARN - ... container "juice" should define livenessProbe
WARN - ... container "juice" should define readinessProbe
FAIL - ... missing resources.limits.cpu
FAIL - ... missing resources.limits.memory
FAIL - ... missing resources.requests.cpu
FAIL - ... missing resources.requests.memory
FAIL - ... must set allowPrivilegeEscalation: false
FAIL - ... must set readOnlyRootFilesystem: true
FAIL - ... must set runAsNonRoot: true
FAIL - ... uses disallowed :latest tag
```

- **Resource controls:** Absent CPU and memory requests/limits mean the scheduler cannot reserve capacity, so noisy-neighbor or DoS scenarios could starve other workloads. Lack of limits also removes guardrails against runaway consumption.
- **Privilege boundaries:** With `runAsNonRoot`, `allowPrivilegeEscalation`, and `readOnlyRootFilesystem` unset, the container starts as UID 0, can escalate, and can mutate its root FS—breaking least privilege and enabling persistence or escape techniques.
- **Image provenance:** The `:latest` tag undermines reproducibility and patch validation; Conftest requires pinning to a known digest or version.
- **Operational health:** Missing readiness/liveness probes leaves Kubernetes unaware of startup failures or hung processes, so traffic could route to unhealthy pods and failures linger indefinitely.

### Hardening Changes in Hardened Manifest

`juice-hardened.yaml` implements the required controls and passes every policy check.

```1:1:labs/lab9/analysis/conftest-hardened.txt
30 tests, 30 passed, 0 warnings, 0 failures, 0 exceptions
```

- **Security context:** `runAsNonRoot: true`, `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`, and `capabilities.drop: ["ALL"]` enforce least privilege and prevent drift.
- **Resource governance:** Requests (`cpu: "100m"`, `memory: "256Mi"`) and limits (`cpu: "500m"`, `memory: "512Mi"`) deliver predictable scheduling and stop resource hogs.
- **Pinned image:** `bkimminich/juice-shop:v19.0.0` removes the implicit `latest` dependency and locks deployments to a vetted build.
- **Health probes:** HTTP liveness/readiness checks ensure the service only receives traffic when fully initialized and is restarted if it stops responding.

### Docker Compose Manifest Analysis

The Compose definition satisfied all compose-specific policies on its first run.

```1:1:labs/lab9/analysis/conftest-compose.txt
15 tests, 15 passed, 0 warnings, 0 failures, 0 exceptions
```

- **User & filesystem posture:** `user: "10001:10001"` keeps execution non-root, while `read_only: true` plus `tmpfs: ["/tmp"]` mimics the Kubernetes read-only root with an ephemeral scratch space.
- **Privilege restrictions:** `cap_drop: ["ALL"]` and `no-new-privileges` match the hardened deployment’s least-privilege stance.
- **Image hygiene:** The service pins the same `v19.0.0` tag, keeping runtime parity with the Kubernetes manifest.

## Key Takeaways

- Falco’s stock detections combined with the targeted `/usr/local/bin` write rule provide clear coverage for interactive shells, drift, and privilege-escalation behaviors in lab conditions.
- Conftest policies effectively distinguish the unhardened deployment, guiding remediation steps that align with least privilege, resource governance, and explicit health monitoring.

