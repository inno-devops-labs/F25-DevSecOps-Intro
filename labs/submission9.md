# Submission 9 — Monitoring & Compliance: Falco Runtime Detection + Conftest Policies

**Author:** Alexander Rozanov • CBS-02 • al.rozanov@innopolis.university  
**Repo Branch:** `feature/lab9`  
**Target:** BusyBox helper container + OWASP Juice Shop manifests  
**Tooling:** Docker, Falco (containerized, eBPF engine), Conftest (OPA/Rego)

---

## 1) Environment & Setup

### 1.1 Host & tools

- Host OS: Linux (Arch-based)
- Container runtime: Docker (rootful, with `--privileged` support for Falco)
- Security tools:
  - **Falco** — containerized, using eBPF/modern eBPF kernel driver
  - **Conftest** — `openpolicyagent/conftest:latest` Docker image
  - **jq** — for parsing Falco JSON events

### 1.2 Lab layout

For this lab I used the following structure:

- `labs/lab9/`
  - `falco/`
    - `rules/custom-rules.yaml` — my custom Falco rule
    - `logs/falco-all.log` — full Falco container logs
    - `logs/falco-events.jsonl` — only Falco JSON events (one per line)
  - `policies/`
    - `k8s-security.rego` — Kubernetes security policies
    - `compose-security.rego` — Docker Compose security policies
  - `manifests/`
    - `k8s/juice-unhardened.yaml` — insecure baseline
    - `k8s/juice-hardened.yaml` — hardened/compliant version
    - `compose/juice-compose.yml` — hardened Docker Compose manifest
  - `analysis/`
    - `falco-selected.json` — filtered Falco events of interest
    - `conftest-unhardened.txt` — Conftest results for baseline K8s manifest
    - `conftest-hardened.txt` — Conftest results for hardened K8s manifest
    - `conftest-compose.txt` — Conftest results for Docker Compose manifest

BusyBox helper workload:

```bash
docker run -d --name lab9-helper alpine:3.19 sleep 1d
````

This container was used to trigger Falco alerts without needing a full application stack.

---

## 2) Task 1 — Runtime Security Detection with Falco

**Objective:** Run Falco with the eBPF driver, trigger built-in alerts from a helper container, add one custom rule, and capture evidence.

### 2.1 Falco deployment (containerized, eBPF engine)

I ran Falco as a privileged container and mounted the host OS paths needed for the eBPF driver:

```bash
sudo docker run -d --name falco \
  --privileged \
  -v /proc:/host/proc:ro \
  -v /boot:/host/boot:ro \
  -v /lib/modules:/host/lib/modules:ro \
  -v /usr:/host/usr:ro \
  -v "$(pwd)/labs/lab9/falco/rules:/rules.d:ro" \
  --entrypoint falco \
  falcosecurity/falco:latest \
    -o json_output=true \
    -o json_include_output_property=true \
    -o log_stderr=true \
    -o log_syslog=false \
    -o engine.kind=modern_ebpf \
    -o rules.files=/etc/falco/falco_rules.yaml,/etc/falco/falco_rules.local.yaml,/rules.d/custom-rules.yaml
```

If `modern_ebpf` is not supported by the kernel, the same command works with:

```bash
-o engine.kind=ebpf
```

Falco emits JSON events to stdout; I captured them from the container logs.

### 2.2 Triggering built-in Falco rules

Inside the `lab9-helper` container I performed several suspicious actions that map to built-in Falco rules:

1. **Interactive shell in container**

   ```bash
   docker exec -it lab9-helper sh -lc 'echo "shell test"; sleep 1'
   ```

   This triggers rules similar to *“Terminal shell in container”* which detect interactive shells spawned inside containers (often used for live debugging or post-exploitation).

2. **Reading sensitive files**

   ```bash
   docker exec lab9-helper sh -lc 'cat /etc/shadow >/dev/null || true'
   ```

   This hits Falco’s rules for reading sensitive files (`/etc/shadow` is a common credential target), indicating potential credential access.

3. **Package management inside container**

   ```bash
   docker exec lab9-helper sh -lc 'apk add --no-cache curl'
   ```

   Installing new packages at runtime is a classic indicator of **container drift** (image is no longer identical to what was originally shipped).

4. **Writing under `/usr/local/bin` (binary directory drift)**

   ```bash
   docker exec --user 0 lab9-helper /bin/sh -lc 'echo boom > /usr/local/bin/drift.txt'
   ```

   Writing to directories that normally contain executables is another form of drift and may be used to drop malicious binaries or wrappers.

#### 2.2.1 Capturing and filtering Falco events

I collected Falco’s logs and extracted just the JSON events:

```bash
sudo docker logs falco > labs/lab9/falco/logs/falco-all.log 2>&1

grep '^{\"time\":' labs/lab9/falco/logs/falco-all.log \
  > labs/lab9/falco/logs/falco-events.jsonl
```

Then I filtered for interesting rules into `labs/lab9/analysis/falco-selected.json`:

```bash
cat labs/lab9/falco/logs/falco-events.jsonl \
  | jq -c 'select(.rule == "Terminal shell in container"
                 or .rule == "Read sensitive file untrusted"
                 or .rule == "Package management in container")' \
  > labs/lab9/analysis/falco-selected.json
```

From these events I could see:

* **Container name**: `lab9-helper`
* **User**: often `root` (UID 0), making the events more critical
* **Process names**: `sh`, `apk`, and others
* **File paths**: `/etc/shadow`, `/usr/local/bin/drift.txt`

Each event includes `time`, `rule`, `priority`, and a detailed `output` line describing what happened and in which container.

### 2.3 Custom Falco rule: writes under `/usr/local/bin`

To practice rule authoring and noise tuning, I added a custom rule that alerts on any write under `/usr/local/bin` inside containers.

Custom rule file: `labs/lab9/falco/rules/custom-rules.yaml`:

```yaml
- rule: Lab9 Write Under UsrLocalBin
  desc: Detect writes under /usr/local/bin inside any container
  condition: evt.type in (open, openat, openat2, creat) and
             evt.is_open_write = true and
             fd.name startswith "/usr/local/bin/" and
             container.id != host
  output: >
    Lab9 Falco: write in /usr/local/bin
    (container=%container.name user=%user.name file=%fd.name proc=%proc.name evt=%evt.type)
  priority: NOTICE
  tags: [lab9, drift, container]
```

After creating the rule, I restarted Falco so it could load the new file (same `docker run` command as above).

To trigger this custom rule:

```bash
docker exec --user 0 lab9-helper /bin/sh -lc 'echo lab9-custom > /usr/local/bin/lab9-custom.txt'
sleep 2
sudo docker logs falco --since 10s | tee labs/lab9/falco/logs/falco-custom.log
```

In `falco-custom.log` I can see an event with:

* `rule`: `Lab9 Write Under UsrLocalBin`
* `priority`: `NOTICE`
* `output`: my custom message, including container name, user, file path and process

This proves that Falco is not only detecting built-in behaviors but is also extendable with lab-specific policies.

### 2.4 Observations & tuning notes

* **Runtime detection**: Falco is effective at catching:

  * Containers used as ad-hoc shells
  * Access to sensitive files like `/etc/shadow`
  * On-the-fly changes such as package installs or file writes under binary directories
* **Drift detection**: The custom rule makes `/usr/local/bin` a protected area; any unexpected write there immediately stands out.
* **Noise & false positives**:

  * In real environments, some rules might need exception lists (e.g. specific maintenance containers that legitimately write under `/usr/local/bin`).
  * Priority levels (e.g. `NOTICE` vs `WARNING` vs `ERROR`) are important to avoid alert fatigue.

---

## 3) Task 2 — Policy-as-Code with Conftest (Rego)

**Objective:** Use Conftest + provided Rego policies to validate K8s and Docker Compose manifests, understand why the baseline fails, and how hardening satisfies the policies.

### 3.1 K8s baseline manifest: `juice-unhardened.yaml` (fails)

Baseline manifest:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: juice-unhardened
spec:
  replicas: 1
  selector:
    matchLabels: { app: juice }
  template:
    metadata:
      labels: { app: juice }
    spec:
      containers:
        - name: juice
          image: bkimminich/juice-shop:latest
          ports:
            - containerPort: 3000
```

I ran Conftest against this file:

```bash
docker run --rm -v "$(pwd)/labs/lab9":/project \
  openpolicyagent/conftest:latest \
  test /project/manifests/k8s/juice-unhardened.yaml \
  -p /project/policies --all-namespaces \
  | tee labs/lab9/analysis/conftest-unhardened.txt
```

The `k8s-security.rego` policy checks for common hardening issues such as:

* Use of `:latest` tags
* Running as root / missing `securityContext`
* Missing resource requests/limits
* Lack of readiness/liveness probes
* Privileged containers / hostPath mounts / host networking

For the **unhardened** manifest, Conftest reports multiple **denials**, for example (conceptually):

* Container uses `:latest` tag → no immutable version tag
* No `securityContext` → container likely runs as root, with all capabilities and a writable root filesystem
* No CPU/memory limits or requests → potential resource abuse
* Missing probes → Kubernetes cannot reliably detect if the app is healthy

This is captured in `labs/lab9/analysis/conftest-unhardened.txt` as failing policies.

### 3.2 Hardened manifest: `juice-hardened.yaml` (passes)

Hardened manifest (simplified):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: juice-hardened
spec:
  replicas: 1
  selector:
    matchLabels: { app: juice }
  template:
    metadata:
      labels: { app: juice }
    spec:
      containers:
        - name: juice
          image: bkimminich/juice-shop:v19.0.0
          securityContext:
            # (non-root user, dropped capabilities, read-only root fs, etc.)
          resources:
            # (CPU/memory requests & limits)
          readinessProbe:
            # HTTP check on /
          livenessProbe:
            # HTTP check on /
```

I tested it with Conftest:

```bash
docker run --rm -v "$(pwd)/labs/lab9":/project \
  openpolicyagent/conftest:latest \
  test /project/manifests/k8s/juice-hardened.yaml \
  -p /project/policies --all-namespaces \
  | tee labs/lab9/analysis/conftest-hardened.txt
```

Compared to the baseline, this manifest includes hardening changes that satisfy the policies:

* **No `:latest` tag**

  * Image pinned to `bkimminich/juice-shop:v19.0.0` → immutable version, better traceability.

* **Security context**

  * Non-root user and group (`runAsNonRoot`, `runAsUser`, `runAsGroup`) → drops root privileges.
  * Dropped capabilities and `allowPrivilegeEscalation: false` → limits kernel-level attack surface.
  * `readOnlyRootFilesystem: true` → stops attackers from modifying application binaries/configs at runtime.

* **Resource management**

  * `resources.requests` / `resources.limits` for CPU and memory → prevents noisy neighbor and DoS scenarios.

* **Health probes**

  * `readinessProbe` and `livenessProbe` → allow Kubernetes to detect broken pods and restart them, improving resilience.

As a result, `labs/lab9/analysis/conftest-hardened.txt` shows the hardened manifest **passing** the policies (no deny-level violations, warnings at most).

### 3.3 Docker Compose manifest: `juice-compose.yml`

Compose manifest:

```yaml
services:
  juice:
    image: bkimminich/juice-shop:v19.0.0
    ports: ["3006:3000"]
    user: "10001:10001"
    read_only: true
    tmpfs: ["/tmp"]
    security_opt:
      - no-new-privileges:true
    cap_drop: ["ALL"]
```

I ran Conftest against it:

```bash
docker run --rm -v "$(pwd)/labs/lab9":/project \
  openpolicyagent/conftest:latest \
  test /project/manifests/compose/juice-compose.yml \
  -p /project/policies --all-namespaces \
  | tee labs/lab9/analysis/conftest-compose.txt
```

The `compose-security.rego` policy checks things like:

* Explicit non-root `user`
* `read_only: true` for services
* Dropping all capabilities (`cap_drop: ["ALL"]`)
* Enabling `no-new-privileges:true`

This manifest is already hardened and satisfies these checks:

* It runs as a non-root UID/GID (`10001:10001`).
* Root filesystem is read-only.
* All Linux capabilities are dropped.
* `no-new-privileges` prevents gaining extra privileges even if a binary is exploited.

The Conftest output for this file shows a **compliant** configuration (no deny-level policy failures).

### 3.4 Falco vs. Conftest: how they complement each other

* **Conftest** works at **config time**:

  * Blocks misconfigured manifests before they ever reach the cluster/runtime.
  * Encodes org policies as Rego code and can be integrated into CI pipelines.

* **Falco** works at **runtime**:

  * Observes real behavior of containers and the kernel.
  * Detects drift, unexpected shells, file access, and privilege escalation attempts, even if config looked OK on paper.

Together they provide defense-in-depth:

* Conftest reduces the attack surface by preventing obviously unsafe configs.
* Falco detects abnormal runtime behavior that slips through or appears later (e.g. attacks, 0-days, manual debugging).

---

## 4) Repro Steps & Artifacts

### 4.1 How to reproduce

1. **Create branch and directories**

   ```bash
   git switch -c feature/lab9
   mkdir -p labs/lab9/falco/{rules,logs} labs/lab9/analysis
   ```

2. **Start helper container**

   ```bash
   docker run -d --name lab9-helper alpine:3.19 sleep 1d
   ```

3. **Run Falco with eBPF (modern or classic)**
   Use the `docker run` command from Section 2.1.

4. **Trigger Falco alerts**
   Run the shell, sensitive file access, package install, and `/usr/local/bin` write commands from Sections 2.2–2.3.

5. **Collect Falco logs**

   ```bash
   sudo docker logs falco > labs/lab9/falco/logs/falco-all.log 2>&1
   grep '^{\"time\":' labs/lab9/falco/logs/falco-all.log \
     > labs/lab9/falco/logs/falco-events.jsonl
   ```

6. **Run Conftest against manifests**

   ```bash
   # Unhardened K8s
   docker run --rm -v "$(pwd)/labs/lab9":/project \
     openpolicyagent/conftest:latest \
     test /project/manifests/k8s/juice-unhardened.yaml \
     -p /project/policies --all-namespaces \
     | tee labs/lab9/analysis/conftest-unhardened.txt

   # Hardened K8s
   docker run --rm -v "$(pwd)/labs/lab9":/project \
     openpolicyagent/conftest:latest \
     test /project/manifests/k8s/juice-hardened.yaml \
     -p /project/policies --all-namespaces \
     | tee labs/lab9/analysis/conftest-hardened.txt

   # Docker Compose
   docker run --rm -v "$(pwd)/labs/lab9":/project \
     openpolicyagent/conftest:latest \
     test /project/manifests/compose/juice-compose.yml \
     -p /project/policies --all-namespaces \
     | tee labs/lab9/analysis/conftest-compose.txt
   ```

7. **Commit and push**

   ```bash
   git add labs/lab9/ labs/submission9.md
   git commit -m "docs: add lab9 submission — Falco + Conftest"
   git push -u origin feature/lab9
   ```

### 4.2 Key artifacts in the PR

* Falco:

  * `labs/lab9/falco/rules/custom-rules.yaml`
  * `labs/lab9/falco/logs/falco-all.log`
  * `labs/lab9/falco/logs/falco-events.jsonl`
  * `labs/lab9/analysis/falco-selected.json`
  * `labs/lab9/falco/logs/falco-custom.log`

* Conftest:

  * `labs/lab9/analysis/conftest-unhardened.txt`
  * `labs/lab9/analysis/conftest-hardened.txt`
  * `labs/lab9/analysis/conftest-compose.txt`

