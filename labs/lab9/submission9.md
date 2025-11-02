# Lab 9

## vl.kuznetsov@innopolis.university


### Task 1 — Falco Runtime Detection

#### Baseline alerts observed from `falco.log`

Two primary baseline alerts were detected:

1. **Terminal shell in container**
    - **Rule:** `Terminal shell in container`
    - **Description:** Triggered when an interactive shell (`sh -lc echo hello-from-shell`) was executed inside the BusyBox container.
    - **Purpose:** Detects users or processes spawning a shell inside a running container — a potential indicator of manual debugging or post-exploitation activity.

2. **Write Binary Under /usr/local/bin (Drift)**
    - **Rule:** `Write Binary Under UsrLocalBin` (custom) and Falco’s built-in drift rule.
    - **Description:** Triggered when a file was written to `/usr/local/bin/drift.txt` from inside the container.
    - **Purpose:** Detects modification of binary paths, which may indicate container drift or tampering.

#### Custom rule purpose and firing conditions

**Rule name:** `Write Binary Under UsrLocalBin`

- **Purpose:** Detects any file creation or write under `/usr/local/bin` from within a container. This helps identify unauthorized binary modifications or persistence attempts inside container images.
- **Should fire when:**
    - A write or create syscall targets a file path beginning with `/usr/local/bin/`.
    - The operation occurs inside a container (not on the host).
    - The event type is `open`, `openat`, `openat2`, or `creat` with write flags.

- **Should NOT fire when:**
    - The operation is read-only.
    - The file is outside `/usr/local/bin/` (e.g., `/tmp` or `/var/log`).
    - The action occurs during container image build time, not at runtime.


### Task 2 — Conftest Policy Analysis

#### Policy violations (unhardened manifest)

The Conftest scan of `juice-unhardened.yaml` reported **8 failures** and **2 warnings**:

| Type | Issue | Why it matters |
|------|--------|----------------|
| ⚠️ Warn | Missing `readinessProbe` | Without readiness checks, Kubernetes may route traffic to containers that aren’t ready, reducing reliability. |
| ⚠️ Warn | Missing `livenessProbe` | Missing liveness checks prevents Kubernetes from detecting and restarting unhealthy containers automatically. |
| ❌ Fail | Missing `resources.limits.cpu` and `resources.limits.memory` | Without limits, a container can consume unbounded CPU or memory, leading to denial-of-service conditions. |
| ❌ Fail | Missing `resources.requests.cpu` and `resources.requests.memory` | Without requests, Kubernetes can’t make accurate scheduling or resource guarantees. |
| ❌ Fail | `allowPrivilegeEscalation` not set to false | Allows processes to gain more privileges than intended (e.g., via `setuid` binaries). |
| ❌ Fail | `readOnlyRootFilesystem` not set to true | A writable root filesystem allows tampering or persistence within a container. |
| ❌ Fail | `runAsNonRoot` not enforced | Running as root increases attack impact if the container is compromised. |
| ❌ Fail | Uses disallowed `:latest` image tag | The `latest` tag is mutable and non-deterministic, which breaks supply chain traceability. |

These violations indicate the image lacks basic runtime security and resource safety controls.

---

#### Hardening changes that satisfied policies

In the hardened manifest (`juice-hardened.yaml`), all tests **passed (30/30)**.  
The following security and compliance improvements were applied:

| Area | Change | Security Benefit |
|-------|---------|------------------|
| Image pinning | Changed `image: bkimminich/juice-shop:latest` → `bkimminich/juice-shop:v19.0.0` | Ensures deterministic builds and prevents unintended upgrades. |
| Privilege control | Added `allowPrivilegeEscalation: false` | Blocks privilege escalation within container processes. |
| Non-root execution | Added `runAsNonRoot: true` | Prevents the app from running as root user inside the container. |
| Immutable filesystem | Added `readOnlyRootFilesystem: true` | Prevents modification of the root FS, mitigating persistence attacks. |
| Dropped capabilities | Added `capabilities: drop: ["ALL"]` | Removes all unnecessary Linux capabilities, minimizing attack surface. |
| Resource management | Added `requests` and `limits` for CPU/memory | Enforces fair scheduling and prevents resource exhaustion. |
| Health probes | Added `livenessProbe` and `readinessProbe` | Improves reliability and auto-recovery of unhealthy pods. |

---

#### Docker Compose manifest analysis

The Conftest scan for the Compose file showed:

15 tests, 15 passed, 0 warnings, 0 failures


This means the Compose deployment meets all policy requirements — for example:
- No privileged containers or `:latest` image tags.
- Correct resource and security options applied.
- Follows least-privilege and immutability principles consistent with Kubernetes hardening.

**Result:**
- Unhardened manifest violates multiple critical runtime and compliance checks.
- Hardened manifest and Compose configuration both fully comply with the defined policies.
