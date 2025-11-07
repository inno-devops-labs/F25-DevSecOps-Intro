
## Task 1 — Runtime Security Detection with Falco

### 1) Baseline alerts captured from `falco.log`

**A) Interactive shell inside container**

- **Rule**: `Terminal shell in container`
- **Severity**: Notice
- **What triggered it**: Running  
  `docker exec -it lab9-helper /bin/sh -lc 'echo hello-from-shell'`
- **Observed details**:
  - Cmdline: `sh -lc "echo hello-from-shell"`
  - Effective user: `root`
  - Container: `lab9-helper` (image `alpine:3.19`)
  - Rationale: built-in rule that flags TTY shells spawned in containers.

**B) Write under `/usr/local/bin` (custom)**

- **Rule**: `Write Binary Under UsrLocalBin` (custom)
- **Severity**: Warning
- **What triggered it**:  
  `docker exec --user 0 lab9-helper /bin/sh -lc 'echo custom-test > /usr/local/bin/custom-rule.txt'`
- **Observed details**:
  - Target file: `/usr/local/bin/custom-rule.txt`
  - Open flags: `O_LARGEFILE|O_TRUNC|O_CREAT|O_WRONLY|O_F_CREATED|FD_UPPER_LAYER`
  - User: `root`
  - Container: `lab9-helper`

### 2) Custom rule — intent and expected behavior

**Rule name**: `Write Binary Under UsrLocalBin`

**Why it exists**  
- Spot unexpected writes to `/usr/local/bin/` inside containers.
- Surface container drift or silent binary drops.
- Narrow the signal compared to generic drift rules by scoping to a high-impact path.

**When it should alert**  
- Syscalls: `open`, `openat`, `openat2`, or `creat` **with write semantics**.
- File path begins with `/usr/local/bin/`.
- Event originated **in a container** (`container.id != host`).
- Examples: adding/replacing helper binaries, post-exploit payload drops.

**When it should stay quiet**  
- Read-only access to files in that directory.
- Host-side file operations.
- Writes outside `/usr/local/bin` (e.g., `/tmp`, `/bin`, `/usr/bin`).
- Legitimate package manager activity by trusted system services (outside container).

---

## Task 2 — Policy-as-Code with Conftest (Rego)

### 1) Findings for the **unhardened** manifest

**Failures (8)** — key issues:
- Image pinned to `:latest` → mutable tag, non-repeatable builds.
- No `runAsNonRoot` → process may run as `root` (privilege risk).
- Missing `allowPrivilegeEscalation: false` → possible escalation path.
- `readOnlyRootFilesystem` not set → writable root FS eases persistence.
- Capabilities not dropped (`drop: ["ALL"]` absent) → excessive privileges.
- No CPU/memory requests/limits → DoS via resource starvation.

**Warnings (2)** — operational resilience:
- Liveness/readiness probes omitted → weaker health management and rollout safety.

### 2) Changes in the **hardened** manifest and their effect

**Result**: all policy checks pass (30/30).

**Remediations applied**:
- **Image immutability**: use a fixed tag (e.g., `v19.0.0`) instead of `:latest`.
- **SecurityContext** hardening:  
  `runAsNonRoot: true`, `allowPrivilegeEscalation: false`,  
  `readOnlyRootFilesystem: true`, `capabilities: { drop: ["ALL"] }`.
- **Resource governance**: define CPU/memory requests and limits.
- **Health checks**: add liveness and readiness probes for safer deploys and restarts.

### 3) Docker Compose assessment

**Outcome**: passes 15 policy checks.

**Why**:
- Service runs as non-root.
- Root filesystem marked read-only where applicable.
- Capabilities are dropped; no-new-privileges enforced.

---
