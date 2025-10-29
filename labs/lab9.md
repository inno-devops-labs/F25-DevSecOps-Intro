# Lab 9 — Monitoring & Compliance: Falco Runtime Detection + Conftest Policies

![difficulty](https://img.shields.io/badge/difficulty-intermediate-orange)
![topic](https://img.shields.io/badge/topic-Monitoring%20%26%20Compliance-blue)
![points](https://img.shields.io/badge/points-10-orange)

> Goal: Detect suspicious container behavior with Falco and enforce deployment hardening via policy-as-code using Conftest (Rego) — all runnable locally.
> Deliverable: A PR from `feature/lab9` with `labs/submission9.md` containing Falco alert evidence, custom rule/tuning notes, Conftest test results, and analysis of provided manifests/policies. Submit the PR link via Moodle.

---

## Overview

In this lab you will practice:
- Runtime threat detection for containers with Falco (eBPF)
- Writing/customizing Falco rules and tuning noise/false positives
- Policy-as-code with Conftest (OPA/Rego) against Kubernetes manifests
- Analyzing how security policies enforce deployment hardening best practices

> Runtime target for Task 1: BusyBox helper container (`alpine:3.19`).

---

## Prerequisites

- Docker (or Docker Desktop)
- `jq`
- Optional: `kubectl` or a local K8s (kind/minikube) is NOT required — Conftest runs offline against YAML

Prepare working directories:
```bash
mkdir -p labs/lab9/{falco/{rules,logs},analysis}
```

---

## Tasks

### Task 1 — Runtime Security Detection with Falco (6 pts)
**Objective:** Run Falco with modern eBPF, trigger alerts from a shell-enabled BusyBox container, and add one custom rule with basic tuning.

#### 1.1: Start a shell-enabled helper container
```bash
# Use Alpine (BusyBox) to trigger events — no app needed
docker run -d --name lab9-helper alpine:3.19 sleep 1d
```

#### 1.2: Run Falco (containerized) with modern eBPF
```bash
# Start Falco container (JSON output to stdout)
docker run -d --name falco \
  --privileged \
  -v /proc:/host/proc:ro \
  -v /boot:/host/boot:ro \
  -v /lib/modules:/host/lib/modules:ro \
  -v /usr:/host/usr:ro \
  -v /var/run/docker.sock:/host/var/run/docker.sock \
  -v "$(pwd)/labs/lab9/falco/rules":/etc/falco/rules.d:ro \
  falcosecurity/falco:latest \
  falco -U \
        -o json_output=true \
        -o time_format_iso_8601=true

# Follow Falco logs
docker logs -f falco | tee labs/lab9/falco/logs/falco.log &
```

Note: The official Falco image defaults to the modern eBPF engine (engine.kind=modern_ebpf). No extra flag is needed beyond running with the required privileges and mounts.

#### 1.3: Trigger two baseline alerts
```bash
# A) Terminal shell inside container (expected rule: Terminal shell in container)
docker exec -it lab9-helper /bin/sh -lc 'echo hello-from-shell'

# B) Container drift: write under a binary directory
# Writes to /usr/local/bin should trigger Falco's drift detection
docker exec --user 0 lab9-helper /bin/sh -lc 'echo boom > /usr/local/bin/drift.txt'
```

#### 1.4: Add one custom Falco rule and validate
Create `labs/lab9/falco/rules/custom-rules.yaml`:
```yaml
# Detect new writable file under /usr/local/bin inside any container
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

Falco auto-reloads rules in `/etc/falco/rules.d`. If you don't see your custom alert after a minute, force a reload:
```bash
docker kill --signal=SIGHUP falco && sleep 2
```

Validate the custom rule by triggering another write:
```bash
# This should trigger BOTH the built-in drift rule AND your custom rule
docker exec --user 0 lab9-helper /bin/sh -lc 'echo custom-test > /usr/local/bin/custom-rule.txt'
```

#### 1.5: Generate Falco test events
```bash
# Falco event generator creates a short burst of detectable actions
docker run --rm --name eventgen \
  --privileged \
  -v /proc:/host/proc:ro -v /dev:/host/dev \
  falcosecurity/event-generator:latest run syscall
```
<details>
<summary>What this does</summary>
Executes a curated set of syscalls (e.g., fileless execution, sensitive file reads) that should appear as Falco alerts. This helps verify your Falco setup is working correctly.
</details>

In `labs/submission9.md`, document:
- Baseline alerts observed from `falco.log`
- Your custom rule’s purpose and when it should/shouldn’t fire

---

### Task 2 — Policy-as-Code with Conftest (Rego) (4 pts)
**Objective:** Run provided security policies against K8s manifests, analyze policy violations, and understand how hardening satisfies compliance requirements.

#### 2.1: Review provided Kubernetes manifests
Open and review the provided manifests:
- `labs/lab9/manifests/k8s/juice-unhardened.yaml` (baseline — do NOT edit)
- `labs/lab9/manifests/k8s/juice-hardened.yaml` (compliant version)

Compare both manifests to understand what hardening changes were applied.

#### 2.2: Review provided Conftest Rego policies
Examine the provided security policies:
- `labs/lab9/policies/k8s-security.rego` — enforces Kubernetes security best practices
- `labs/lab9/policies/compose-security.rego` — enforces Docker Compose security patterns

These policies check for common misconfigurations like running as root, missing resource limits, privileged containers, etc.

#### 2.3: Run Conftest against both manifests
```bash
# Test unhardened manifest (expect policy violations)
docker run --rm -v "$(pwd)/labs/lab9":/project \
  openpolicyagent/conftest:latest \
  test /project/manifests/k8s/juice-unhardened.yaml -p /project/policies --all-namespaces | tee labs/lab9/analysis/conftest-unhardened.txt

# Test hardened manifest (should pass or only warnings)
docker run --rm -v "$(pwd)/labs/lab9":/project \
  openpolicyagent/conftest:latest \
  test /project/manifests/k8s/juice-hardened.yaml -p /project/policies --all-namespaces | tee labs/lab9/analysis/conftest-hardened.txt

# Test Docker Compose manifest
docker run --rm -v "$(pwd)/labs/lab9":/project \
  openpolicyagent/conftest:latest \
  test /project/manifests/compose/juice-compose.yml -p /project/policies --all-namespaces | tee labs/lab9/analysis/conftest-compose.txt
```

In `labs/submission9.md`, document:
- The policy violations from the unhardened manifest and why each matters for security
- The specific hardening changes in the hardened manifest that satisfy policies
- Analysis of the Docker Compose manifest results

---

## Acceptance Criteria

- ✅ Branch `feature/lab9` contains Falco setup, logs, and a custom rule file
- ✅ At least two Falco alerts captured and explained (baseline + custom)
- ✅ Conftest policies reviewed and tested against manifests
- ✅ Unhardened K8s manifest fails; hardened manifest passes (warnings OK)
- ✅ `labs/submission9.md` includes evidence and analysis for both tasks

---

## How to Submit

1. Create a branch and push it to your fork:
```bash
git switch -c feature/lab9
# create labs/submission9.md with your findings
git add labs/lab9/ labs/submission9.md
git commit -m "docs: add lab9 — falco runtime + conftest policies"
git push -u origin feature/lab9
```
2. Open a PR from your fork’s `feature/lab9` → course repo’s `main`.
3. In the PR description include:
```text
- [x] Task 1 — Falco runtime detection (alerts + custom rule)
- [x] Task 2 — Conftest policies (fail→pass hardening)
```
4. Submit the PR URL via Moodle before the deadline.

---

## Rubric (10 pts)

| Criterion                                                       | Points |
| --------------------------------------------------------------- | -----: |
| Task 1 — Falco runtime detection + custom rule                  |    6.0 |
| Task 2 — Conftest policies + hardened manifests                 |    4.0 |
| Total                                                           |   10.0 |

---

## Guidelines

- Keep Falco running while you trigger events; copy only relevant alert lines into your submission
- Place custom Falco rules under `labs/lab9/falco/rules/` and commit them
- Conftest “deny” enforces hard requirements; “warn” provides guidance without failing
- Aim for minimal, practical policies that reflect production hardening baselines

<details>
<summary>References</summary>

- Falco: https://falco.org/docs/
- Falco container: https://github.com/falcosecurity/falco
- Event Generator: https://github.com/falcosecurity/event-generator
- Conftest: https://github.com/open-policy-agent/conftest
- OPA/Rego: https://www.openpolicyagent.org/docs/

</details>

<details>
<summary>Troubleshooting</summary>

- Falco engine: If Falco logs show that modern eBPF is unsupported, switch engine with: `-o engine.kind=ebpf` in the `docker run` command.
- Permissions: Ensure Docker is running and you can run privileged containers. If `--privileged` or mounts fail, try a Linux host or WSL2.
- Container context: For drift tests, write from inside the container (not `docker cp`) so Falco reports a non-host `container.id`.
- Conftest: If pulling the image fails, try specifying a version tag, e.g., `openpolicyagent/conftest:v0.63.0`.

</details>

### Cleanup
```bash
docker rm -f falco lab9-helper 2>/dev/null || true
```
