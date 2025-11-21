# Lab 12 — Kata Containers: VM-backed Container Sandboxing (Local)

![difficulty](https://img.shields.io/badge/difficulty-intermediate-orange)
![topic](https://img.shields.io/badge/topic-Container%20Sandboxing-blue)
![points](https://img.shields.io/badge/points-10-orange)

> Goal: Run OWASP Juice Shop under Kata Containers to experience VM-backed container isolation, compare it with the default runc runtime, and document security/operational trade-offs.
> Deliverable: A PR from `feature/lab12` with `labs/submission12.md` containing setup evidence, runtime comparisons (runc vs kata), isolation tests, and a brief performance summary with recommendations.

---

## Overview

In this lab you will practice:
- Installing/Configuring Kata Containers as a Docker/containerd runtime (Linux)
- Running the same workload (Juice Shop) with `runc` vs `kata-runtime`
- Observing isolation differences (guest kernel, process visibility, restricted operations)
- Measuring basic performance characteristics and trade-offs

> VM-backed sandboxes like Kata place each container/pod inside a lightweight VM, adding a strong isolation boundary while preserving container UX.

---

## Prerequisites

Before starting, ensure you have:
- ✅ Linux host with hardware virtualization enabled (Intel VT-x or AMD-V)
  - Check: `egrep -c '(vmx|svm)' /proc/cpuinfo` (should return > 0)
  - Nested virtualization required if running inside a VM
- ✅ containerd (1.7+) and nerdctl (1.7+) with root/sudo privileges
- ✅ `jq`, `curl`, and `awk` installed
- ✅ At least 4GB RAM and 10GB free disk space
- ✅ ~60-90 minutes available (installation can take time)

Install containerd + nerdctl (example on Debian/Ubuntu):
```bash
sudo apt-get update && sudo apt-get install -y containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo systemctl enable --now containerd

# Install nerdctl (binary)
VER=2.2.0
curl -fL -o /tmp/nerdctl.tgz "https://github.com/containerd/nerdctl/releases/download/v${VER}/nerdctl-${VER}-linux-amd64.tar.gz"
sudo tar -C /usr/local/bin -xzf /tmp/nerdctl.tgz nerdctl && rm /tmp/nerdctl.tgz

containerd --version
sudo nerdctl --version

# Prepare working directories
mkdir -p labs/lab12/{setup,runc,kata,isolation,bench,analysis}
```

If you plan to use the Kata assets installer, ensure `zstd` is available for extracting the release tarball:
```bash
sudo apt-get install -y zstd jq
```

---

## Tasks

### Task 1 — Install and Configure Kata (2 pts)
⏱️ **Estimated time:** 20-30 minutes

**Objective:** Install Kata and make it available to containerd (nerdctl) as `io.containerd.kata.v2`.

#### 1.1: Install Kata

- Build the Kata Rust runtime in a container and copy the shim to your host:

```bash
# Build inside a Rust container; output goes to labs/lab12/setup/kata-out/
bash labs/lab12/setup/build-kata-runtime.sh

# Install the shim onto your host PATH (requires sudo)
sudo install -m 0755 labs/lab12/setup/kata-out/containerd-shim-kata-v2 /usr/local/bin/
command -v containerd-shim-kata-v2 && containerd-shim-kata-v2 --version | tee labs/lab12/setup/kata-built-version.txt
```

Notes:
- The runtime alone is not sufficient; Kata also needs a guest kernel + rootfs image. Prefer your distro packages for these artifacts, or follow the upstream docs to obtain them. If you already have Kata installed, replacing just the shim binary is typically sufficient for this lab.

- Install Kata assets and default config (runtime-rs):
```bash
sudo bash labs/lab12/scripts/install-kata-assets.sh        # downloads kata-static and wires configuration
```
  - If you see an error like "load TOML config failed" when running a Kata container, it means the default configuration file is missing. The script above creates `/etc/kata-containers/runtime-rs/configuration.toml` pointing to the installed defaults.

#### 1.2: Configure containerd + nerdctl
- Enable `io.containerd.kata.v2` per Kata docs (Kata 3’s shim is `containerd-shim-kata-v2`).
- Minimal config example for config version 3 (most current containerd):
```toml
[plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.kata]
  runtime_type = 'io.containerd.kata.v2'
```
  - Legacy configs may use:
```toml
[plugins.'io.containerd.grpc.v1.cri'.containerd.runtimes.kata]
  runtime_type = 'io.containerd.kata.v2'
```

Automated update (recommended):
```bash
sudo bash labs/lab12/scripts/configure-containerd-kata.sh           # updates /etc/containerd/config.toml
```
- Restart and verify a test container:
```bash
sudo systemctl restart containerd
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 uname -a
```

In `labs/submission12.md`, document:

**Task 1 Requirements:**
- Show the shim `containerd-shim-kata-v2 --version`
- Show a successful test run with `sudo nerdctl run --runtime io.containerd.kata.v2 ...`

---

### Task 2 — Run and Compare Containers (runc vs kata) (3 pts)
⏱️ **Estimated time:** 15-20 minutes

**Objective:** Run workloads with both runtimes and compare their environments.

#### 2.1: Start runc container (Juice Shop)
```bash
# runc (default under nerdctl) - full application
sudo nerdctl run -d --name juice-runc -p 3012:3000 bkimminich/juice-shop:v19.0.0

# Wait for readiness
sleep 10
curl -s -o /dev/null -w "juice-runc: HTTP %{http_code}\n" http://localhost:3012 | tee labs/lab12/runc/health.txt
```

#### 2.2: Run Kata containers (Alpine-based tests)

> **Note:** Due to a known issue with nerdctl + Kata runtime-rs v3 and long-running detached containers,
> we'll use short-lived Alpine containers for Kata demonstrations.

```bash
echo "=== Kata Container Tests ==="
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 uname -a | tee labs/lab12/kata/test1.txt
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 uname -r | tee labs/lab12/kata/kernel.txt
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 sh -c "grep 'model name' /proc/cpuinfo | head -1" | tee labs/lab12/kata/cpu.txt
```

#### 2.3: Kernel comparison (Key finding)

```bash
echo "=== Kernel Version Comparison ===" | tee labs/lab12/analysis/kernel-comparison.txt
echo -n "Host kernel (runc uses this): " | tee -a labs/lab12/analysis/kernel-comparison.txt
uname -r | tee -a labs/lab12/analysis/kernel-comparison.txt

echo -n "Kata guest kernel: " | tee -a labs/lab12/analysis/kernel-comparison.txt
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 cat /proc/version | tee -a labs/lab12/analysis/kernel-comparison.txt
```

#### 2.4: CPU virtualization check

```bash
echo "=== CPU Model Comparison ===" | tee labs/lab12/analysis/cpu-comparison.txt
echo "Host CPU:" | tee -a labs/lab12/analysis/cpu-comparison.txt
grep "model name" /proc/cpuinfo | head -1 | tee -a labs/lab12/analysis/cpu-comparison.txt

echo "Kata VM CPU:" | tee -a labs/lab12/analysis/cpu-comparison.txt
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 sh -c "grep 'model name' /proc/cpuinfo | head -1" | tee -a labs/lab12/analysis/cpu-comparison.txt
```

In `labs/submission12.md`, document:

**Task 2 Requirements:**
- Show juice-runc health check (HTTP 200 from port 3012)
- Show Kata containers running successfully with `--runtime io.containerd.kata.v2`
- Compare kernel versions:
  - runc uses host kernel (same as `uname -r`)
  - Kata uses separate guest kernel (6.12.47 or similar)
- Compare CPU models (real vs virtualized)
- Explain isolation implications:
  - **runc**: ?
  - **Kata**: ?

---

### Task 3 — Isolation Tests (3 pts)
⏱️ **Estimated time:** 15 minutes

**Objective:** Observe and compare isolation characteristics between runc and Kata.

#### 3.1: Kernel ring buffer (dmesg) access

This demonstrates the most significant isolation difference:

```bash
echo "=== dmesg Access Test ===" | tee labs/lab12/isolation/dmesg.txt

echo "Kata VM (separate kernel boot logs):" | tee -a labs/lab12/isolation/dmesg.txt  
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 dmesg 2>&1 | head -5 | tee -a labs/lab12/isolation/dmesg.txt
```

**Key observation:** Kata containers show VM boot logs, proving they run in a separate kernel.

#### 3.2: /proc filesystem visibility

```bash
echo "=== /proc Entries Count ===" | tee labs/lab12/isolation/proc.txt

echo -n "Host: " | tee -a labs/lab12/isolation/proc.txt
ls /proc | wc -l | tee -a labs/lab12/isolation/proc.txt

echo -n "Kata VM: " | tee -a labs/lab12/isolation/proc.txt
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 sh -c "ls /proc | wc -l" | tee -a labs/lab12/isolation/proc.txt
```

#### 3.3: Network interfaces

```bash
echo "=== Network Interfaces ===" | tee labs/lab12/isolation/network.txt

echo "Kata VM network:" | tee -a labs/lab12/isolation/network.txt
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 ip addr | tee -a labs/lab12/isolation/network.txt
```

#### 3.4: Kernel modules

```bash
echo "=== Kernel Modules Count ===" | tee labs/lab12/isolation/modules.txt

echo -n "Host kernel modules: " | tee -a labs/lab12/isolation/modules.txt
ls /sys/module | wc -l | tee -a labs/lab12/isolation/modules.txt

echo -n "Kata guest kernel modules: " | tee -a labs/lab12/isolation/modules.txt
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 sh -c "ls /sys/module 2>/dev/null | wc -l" | tee -a labs/lab12/isolation/modules.txt
```

In `labs/submission12.md`, document:

**Task 3 Requirements:**
- Show dmesg output differences (Kata shows VM boot logs, proving separate kernel)
- Compare /proc filesystem visibility
- Show network interface configuration in Kata VM
- Compare kernel module counts (host vs guest VM)
- Explain isolation boundary differences:
  - **runc**: ?
  - **kata**: ?
- Discuss security implications:
  - Container escape in runc = ?
  - Container escape in Kata = ?

---

### Task 4 — Performance Comparison (2 pts)
⏱️ **Estimated time:** 10 minutes

**Objective:** Compare startup time and overhead between runc and Kata.

#### 4.1: Container startup time comparison

```bash
echo "=== Startup Time Comparison ===" | tee labs/lab12/bench/startup.txt

echo "runc:" | tee -a labs/lab12/bench/startup.txt
time sudo nerdctl run --rm alpine:3.19 echo "test" 2>&1 | grep real | tee -a labs/lab12/bench/startup.txt

echo "Kata:" | tee -a labs/lab12/bench/startup.txt
time sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 echo "test" 2>&1 | grep real | tee -a labs/lab12/bench/startup.txt
```

#### 4.2: HTTP response latency (juice-runc only)

```bash
echo "=== HTTP Latency Test (juice-runc) ===" | tee labs/lab12/bench/http-latency.txt
out="labs/lab12/bench/curl-3012.txt"
: > "$out"

for i in $(seq 1 50); do
  curl -s -o /dev/null -w "%{time_total}\n" http://localhost:3012/ >> "$out"
done

echo "Results for port 3012 (juice-runc):" | tee -a labs/lab12/bench/http-latency.txt
awk '{s+=$1; n+=1} END {if(n>0) printf "avg=%.4fs min=%.4fs max=%.4fs n=%d\n", s/n, min, max, n}' \
  min=$(sort -n "$out" | head -1) max=$(sort -n "$out" | tail -1) "$out" | tee -a labs/lab12/bench/http-latency.txt
```

In `labs/submission12.md`, document:

**Task 4 Requirements:**
- Show startup time comparison (runc: <1s, Kata: 3-5s)
- Show HTTP latency for juice-runc baseline
- Analyze performance tradeoffs:
  - **Startup overhead**: ?
  - **Runtime overhead**: ?
  - **CPU overhead**: ?
- Interpret when to use each:
  - **Use runc when**: ?
  - **Use Kata when**: ?

---

## Acceptance Criteria

- ✅ Kata shim installed and verified (`containerd-shim-kata-v2 --version`)
- ✅ containerd configured; runtime `io.containerd.kata.v2` used for `juice-kata`
- ✅ runc vs kata containers both reachable; environment differences captured
- ✅ Isolation tests executed and results summarized
- ✅ Basic latency snapshot recorded and discussed
- ✅ All artifacts saved under `labs/lab12/` and committed

---

## Known Issues and Troubleshooting

### nerdctl + Kata runtime-rs detached container issue

**Symptom:** Long-running detached containers fail with:
```
FATA[0001] failed to create shim task: Others("failed to handle message create container
Caused by:
    0: open stdout
    1: No such file or directory (os error 2)
```

**Root Cause:** Race condition in logging initialization between nerdctl and Kata runtime-rs v3.

**Workarounds:**
1. Use short-lived/interactive containers (as in this lab)
2. Use Kubernetes with Kata (fully supported)
3. Use Docker with older Kata versions
4. Use containerd's `ctr` command directly

**Status:** Known issue, fix expected in future releases.

### Verifying Kata is working

If you encounter issues, verify Kata basics:

```bash
# Test simple execution
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 echo "Kata works"

# Check kernel version (should be 6.12.47 or similar, NOT your host kernel)
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 uname -r

# Check Kata shim
ls -la /usr/local/bin/containerd-shim-kata-v2
containerd-shim-kata-v2 --version

# Check containerd logs
sudo journalctl -u containerd -n 50 --no-pager | grep -i kata
```

---

## How to Submit

1. Create a branch and push it to your fork:
```bash
git switch -c feature/lab12
# create labs/submission12.md with your findings
git add labs/lab12/ labs/submission12.md
git commit -m "docs: add lab12 — kata containers sandboxing"
git push -u origin feature/lab12
```
2. Open a PR from your fork’s `feature/lab12` → course repo’s `main`.
3. In the PR description include:
```text
- [x] Task 1 — Kata install + runtime config
- [x] Task 2 — runc vs kata runtime comparison
- [x] Task 3 — Isolation tests
- [x] Task 4 — Basic performance snapshot
```
4. Submit the PR URL via Moodle before the deadline.

---

## Rubric (10 pts)

| Criterion                                              | Points |
| ------------------------------------------------------ | -----: |
| Task 1 — Install + Configure Kata                      |    2.0 |
| Task 2 — Run and Compare (runc vs kata)                |    3.0 |
| Task 3 — Isolation Tests                               |    3.0 |
| Task 4 — Performance Snapshot                          |    2.0 |
| Total                                                  |   10.0 |

---

## Guidelines

- Prefer non-privileged containers; avoid `--privileged` unless a test explicitly calls for it
- Use containerd+nerdctl with `io.containerd.kata.v2` per Kata 3 docs (Docker `--runtime=kata` is legacy)
- Nested virtualization must be enabled if inside a VM (check your cloud provider or hypervisor settings)
- Use clear, concise evidence in `submission12.md` and focus your analysis on isolation trade-offs vs operational overhead

<details>
<summary>References</summary>

- Kata Containers: https://github.com/kata-containers/kata-containers
- Install docs (Kata 3): https://github.com/kata-containers/kata-containers/tree/main/docs/install
- containerd runtime config: https://github.com/kata-containers/kata-containers/tree/main/docs

</details>
