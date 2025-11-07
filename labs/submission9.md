# Lab 9 Submission — Falco Runtime Detection + Conftest Policies

## Task 1 — Falco Runtime Security 

### 1. Baseline alerts (copy relevant JSON lines)
Paste 2+ alert entries from `labs/lab9/falco/logs/falco.log`:

```
{"hostname":"b7f390f76ccb","output":"2025-11-07T09:12:01.784608219+0000: Notice A shell was spawned in a container with an attached terminal | evt_type=execve user=root user_uid=0 user_loginuid=-1 process=sh proc_exepath=/bin/busybox parent=containerd-shim command=sh -lc echo hello-from-shell terminal=34816 exe_flags=EXE_WRITABLE|EXE_LOWER_LAYER container_id=743e27f4138a container_name=lab9-helper container_image_repository=alpine container_image_tag=3.19 k8s_pod_name=<NA> k8s_ns_name=<NA>","output_fields":{"container.id":"743e27f4138a","container.image.repository":"alpine","container.image.tag":"3.19","container.name":"lab9-helper","evt.arg.flags":"EXE_WRITABLE|EXE_LOWER_LAYER","evt.time.iso8601":1762506721784608219,"evt.type":"execve","k8s.ns.name":null,"k8s.pod.name":null,"proc.cmdline":"sh -lc echo hello-from-shell","proc.exepath":"/bin/busybox","proc.name":"sh","proc.pname":"containerd-shim","proc.tty":34816,"user.loginuid":-1,"user.name":"root","user.uid":0},"priority":"Notice","rule":"Terminal shell in container","source":"syscall","tags":["T1059","container","maturity_stable","mitre_execution","shell"],"time":"2025-11-07T09:12:01.784608219Z"}
{"hostname":"b7f390f76ccb","output":"2025-11-07T09:12:01.838856290+0000: Warning Falco Custom: File write in /usr/local/bin (container=lab9-helper user=root file=/usr/local/bin/drift.txt flags=O_LARGEFILE|O_TRUNC|O_CREAT|O_WRONLY|O_F_CREATED|FD_UPPER_LAYER) container_id=743e27f4138a container_name=lab9-helper container_image_repository=alpine container_image_tag=3.19 k8s_pod_name=<NA> k8s_ns_name=<NA>","output_fields":{"container.id":"743e27f4138a","container.image.repository":"alpine","container.image.tag":"3.19","container.name":"lab9-helper","evt.arg.flags":"O_LARGEFILE|O_TRUNC|O_CREAT|O_WRONLY|O_F_CREATED|FD_UPPER_LAYER","evt.time.iso8601":1762506721838856290,"fd.name":"/usr/local/bin/drift.txt","k8s.ns.name":null,"k8s.pod.name":null,"user.name":"root"},"priority":"Warning","rule":"Write Binary Under UsrLocalBin","source":"syscall","tags":["compliance","container","drift"],"time":"2025-11-07T09:12:01.838856290Z"}
```

### 2. Custom rule
- Name: `Write Binary Under UsrLocalBin`
- Purpose: Detect writes to `/usr/local/bin/*` inside any container to catch drift and potential persistence mechanisms.
- Should fire when: a container process opens/creates a file under `/usr/local/bin` with write flags.
- Should NOT fire when: the event is on the host (`container.id == host`) or writes occur outside `/usr/local/bin`.

Custom rule file reference: `labs/lab9/falco/rules/custom-rules.yaml`

---



## Task 2 — Conftest Policies 

### 1. Unhardened manifest — policy violations
Command output: `labs/lab9/analysis/conftest-unhardened.txt` (20 passed, 2 warnings, 8 failures).

Key violations and why they matter:
- Missing resources.requests/limits (cpu, memory): no QoS guarantees; risk of OOM/noisy-neighbor.
- allowPrivilegeEscalation not false: potential local privilege escalation.
- readOnlyRootFilesystem not true: enables runtime drift and persistence.
- runAsNonRoot not true: running as root increases blast radius.
- Image tag is :latest: non-immutable and non-reproducible deployments.
- Warnings: missing readinessProbe/livenessProbe → weaker health checks/self-healing.

### 2. Hardened manifest — pass/warn
Command output: `labs/lab9/analysis/conftest-hardened.txt` → 30/30 passed, 0 warnings.

Hardening applied in `labs/lab9/manifests/k8s/juice-hardened.yaml`:
- Pinned image tag `bkimminich/juice-shop:v19.0.0` (no :latest).
- securityContext: `runAsNonRoot: true`, `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`, `capabilities.drop: ["ALL"]`.
- resources: requests and limits for cpu and memory.
- Probes: readinessProbe and livenessProbe defined.

### 3. Docker Compose analysis
Command output: `labs/lab9/analysis/conftest-compose.txt` → 15/15 passed, 0 warnings.

Why it passes (`labs/lab9/manifests/compose/juice-compose.yml`):
- Non-root `user: "10001:10001"`.
- Read-only FS with `read_only: true` and `tmpfs: ["/tmp"]`.
- `security_opt: [ no-new-privileges:true ]` and `cap_drop: ["ALL"]`.
- Pinned image tag `v19.0.0`.
