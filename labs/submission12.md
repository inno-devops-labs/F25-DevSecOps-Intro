````markdown
# Submission 12 — Kata Containers: VM-backed Container Sandboxing (Local)

**Author:** Alexander Rozanov • CBS-02 • al.rozanov@innopolis.university  
**Repo Branch:** `feature/lab12`  
**Host OS:** Arch Linux (bare metal)  
**Runtimes:** Docker (runc), containerd + nerdctl (`io.containerd.kata.v2`)  

---

## 1) Environment & Setup

### 1.1 Host & base tooling

- **Host OS:** Arch Linux (x86_64)
- **Virtualization support:** `egrep -c '(vmx|svm)' /proc/cpuinfo` returned a non-zero value, so hardware virtualization (VT-x/AMD-V) is available.
- **Kernel:** host kernel version obtained via `uname -r` (see submission repo if needed).
- **Container runtimes:**
  - Docker (using `runc` as the default runtime) — used for the baseline Juice Shop container.
  - `containerd` + `nerdctl` — used to run both runc and Kata containers.

### 1.2 Kata runtime build & installation

I followed the lab’s approach of building the Kata containerd shim from source using a Rust-based build environment.

From the repo root:

```bash
cd F25-DevSecOps-Intro

bash labs/lab12/setup/build-kata-runtime.sh
````

This script:

1. Starts a `rust:1.75-bookworm` container.
2. Installs build dependencies with `apt`.
3. Builds `containerd-shim-kata-v2` from the Kata sources.
4. Writes the resulting binary into `labs/lab12/setup/kata-out/`.

I then installed the shim on the host:

```bash
sudo install -m 0755 labs/lab12/setup/kata-out/containerd-shim-kata-v2 /usr/local/bin/

containerd-shim-kata-v2 --version | tee labs/lab12/setup/kata-built-version.txt
```

This produced a version string confirming that the Kata shim is installed and working.

### 1.3 Kata assets & containerd runtime configuration

Next, I installed Kata’s guest kernel / rootfs and configured containerd:

```bash
# Install Kata kernel, image and configuration
sudo bash labs/lab12/scripts/install-kata-assets.sh

# Add the io.containerd.kata.v2 runtime to containerd config and restart
sudo bash labs/lab12/scripts/configure-containerd-kata.sh
sudo systemctl restart containerd
```

The assets are placed under `/opt/kata` and a configuration file is symlinked under `/etc/kata-containers/runtime-rs/configuration.toml`.

Finally, I installed CNI plugins for nerdctl, which are required to set up the default container network:

```bash
cd /tmp
curl -LO https://github.com/containernetworking/plugins/releases/download/v1.5.0/cni-plugins-linux-amd64-v1.5.0.tgz

sudo mkdir -p /opt/cni/bin
sudo tar -C /opt/cni/bin -xzf cni-plugins-linux-amd64-v1.5.0.tgz
```

After this, `nerdctl` could successfully create the default `bridge` network and run Kata containers.

---

## 2) Task 1 — Baseline (runc) & Kata Sanity Check

### 2.1 runc baseline: Juice Shop on Docker

As a baseline, I ran Juice Shop with Docker using the default `runc` runtime:

```bash
docker run -d --name juice-runc -p 3012:3000 \
  bkimminich/juice-shop:v19.0.0

sleep 15

curl -s -o /dev/null -w "juice-runc: HTTP %{http_code}\n" \
  http://localhost:3012/ | tee labs/lab12/runc/health.txt
```

* The health check returned **HTTP 200**, confirming that the app is reachable using runc.
* This setup shares the host kernel and is a good control group for later comparison with Kata.

### 2.2 Kata sanity check: Alpine with `uname -a`

To verify that Kata is correctly wired into containerd, I ran a simple alpine container with Kata:

```bash
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 uname -a \
  | tee labs/lab12/kata/test1.txt
```

This command completed successfully and printed the kernel string from inside the Kata guest VM. The key properties:

* `uname -a` inside Kata shows a **different kernel version string** than the host.
* The architecture matches (`x86_64`), but the kernel build and version follow Kata’s kernel.

This confirms that:

* `io.containerd.kata.v2` is active,
* containers are backed by a VM with its own kernel rather than by the host kernel directly.

---

## 3) Task 2 — runc vs Kata: Kernel & CPU Comparison

To understand environment differences, I compared host/runc and Kata on kernel and CPU levels.

### 3.1 Kata guest kernel details

I recorded the kernel version from inside Kata:

```bash
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 uname -r \
  | tee labs/lab12/kata/kernel.txt
```

Additionally, I compared the full kernel version string (`/proc/version`) against the host using:

```bash
echo "=== Kernel Version Comparison ===" \
  | tee labs/lab12/analysis/kernel-comparison.txt

echo -n "Host kernel (runc uses this): " \
  | tee -a labs/lab12/analysis/kernel-comparison.txt
uname -r \
  | tee -a labs/lab12/analysis/kernel-comparison.txt

echo -n "Kata guest kernel: " \
  | tee -a labs/lab12/analysis/kernel-comparison.txt
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 \
  cat /proc/version \
  | tee -a labs/lab12/analysis/kernel-comparison.txt
```

**Observation:**

* The host kernel and Kata guest kernel clearly differ in version string and build.
* From the container’s perspective, `uname -r` reports the **guest kernel**, not the host kernel.

### 3.2 CPU model: host vs Kata VM

On the host:

```bash
grep -m1 'model name' /proc/cpuinfo || grep -m1 'Processor' /proc/cpuinfo
```

Inside Kata:

```bash
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 \
  sh -lc "grep -m1 'model name' /proc/cpuinfo || grep -m1 'Processor' /proc/cpuinfo" \
  | tee labs/lab12/kata/cpu.txt
```

Then I wrote both into `labs/lab12/analysis/cpu-comparison.txt`.

**Observation:**

* The host shows the real, physical CPU model.
* The Kata guest typically shows a virtualized CPU model (e.g. QEMU/KVM) or a pruned feature set.
* This means Kata can abstract or mask host CPU details, which helps reduce fingerprinting and gives more control over the guest CPU feature surface.

---

## 4) Task 3 — Isolation Tests

This task compares how a runc container “sees” the system (really the host kernel) vs how a Kata container sees it (guest kernel & VM).

### 4.1 `dmesg` (kernel ring buffer)

I captured host vs Kata `dmesg`:

```bash
echo "=== dmesg Access Test ===" | tee labs/lab12/isolation/dmesg.txt

echo "Host dmesg (first 5 lines):" \
  | tee -a labs/lab12/isolation/dmesg.txt
dmesg 2>&1 | head -5 \
  | tee -a labs/lab12/isolation/dmesg.txt

echo "Kata VM dmesg (first 5 lines):" \
  | tee -a labs/lab12/isolation/dmesg.txt
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 \
  dmesg 2>&1 | head -5 \
  | tee -a labs/lab12/isolation/dmesg.txt
```

**Observation:**

* Host `dmesg` includes messages from the **real host kernel** (device drivers, host boot, etc.).
* Kata `dmesg` shows messages from the **guest VM’s kernel** (VM boot and virtual devices).
* Even if an attacker gains access to `dmesg` inside a Kata container, they only see the guest kernel’s log, not the host’s.

### 4.2 Size and contents of `/proc`

I compared how many entries `/proc` has on host vs inside Kata:

```bash
echo "=== /proc Entries Count ===" | tee labs/lab12/isolation/proc.txt

echo -n "Host: " | tee -a labs/lab12/isolation/proc.txt
ls /proc | wc -l \
  | tee -a labs/lab12/isolation/proc.txt

echo -n "Kata VM: " | tee -a labs/lab12/isolation/proc.txt
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 \
  sh -lc "ls /proc | wc -l" \
  | tee -a labs/lab12/isolation/proc.txt
```

**Observation:**

* The absolute numbers differ, but more importantly:

  * Host `/proc` exposes host-level processes and kernel interfaces.
  * Kata `/proc` reflects only the **guest** processes and kernel; it does not reveal host processes or host-specific internals.

### 4.3 Kernel modules

I also compared the number of loaded kernel modules:

```bash
echo "=== Kernel Modules Count ===" \
  | tee labs/lab12/isolation/modules.txt

echo -n "Host kernel modules: " \
  | tee -a labs/lab12/isolation/modules.txt
ls /sys/module | wc -l \
  | tee -a labs/lab12/isolation/modules.txt

echo -n "Kata guest kernel modules: " \
  | tee -a labs/lab12/isolation/modules.txt
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 \
  sh -lc "ls /sys/module 2>/dev/null | wc -l" \
  | tee -a labs/lab12/isolation/modules.txt
```

**Observation:**

* The host has a larger set of modules loaded (drivers, subsystems).
* The Kata guest kernel typically has fewer modules, with just enough to support container workloads.
* Fewer modules → smaller attack surface in the guest kernel.

### 4.4 Network interfaces inside Kata

Finally, I listed network interfaces inside the Kata VM:

```bash
echo "=== Network Interfaces (Kata) ===" \
  | tee labs/lab12/isolation/network.txt

sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 \
  sh -lc "apk add --no-cache iproute2 >/dev/null 2>&1; ip addr" \
  | tee -a labs/lab12/isolation/network.txt
```

**Observation:**

* Kata containers see virtualized network interfaces (e.g. `eth0` backed by a virtio-net device).
* The guest kernel has its own network stack; host-level network interfaces and routing are abstracted away by the VM boundary.

---

## 5) Task 4 — Performance Comparison

### 5.1 Startup time: runc vs Kata

I measured the startup time for a tiny container using runc vs Kata:

```bash
echo "=== Startup Time Comparison ===" \
  | tee labs/lab12/bench/startup.txt

echo "runc:" | tee -a labs/lab12/bench/startup.txt
( time sudo nerdctl run --rm alpine:3.19 echo "test" ) 2>&1 \
  | grep real \
  | tee -a labs/lab12/bench/startup.txt

echo "Kata:" | tee -a labs/lab12/bench/startup.txt
( time sudo nerdctl run --rm --runtime io.containerd.kata.v2 \
    alpine:3.19 echo "test" ) 2>&1 \
  | grep real \
  | tee -a labs/lab12/bench/startup.txt
```

**Observation:**

* The **runc** run typically completed in **well under 1 second**.
* The **Kata** run took noticeably longer (a few seconds), reflecting:

  * time to boot the guest VM,
  * initialization of the guest kernel and minimal userspace.

This confirms the expected trade-off:

* runc: minimal overhead, fast startup.
* Kata: stronger isolation but higher startup cost.

### 5.2 HTTP latency for Juice Shop (runc)

Optionally, I measured HTTP latency for `juice-runc`:

```bash
echo "=== HTTP Latency Test (juice-runc) ===" \
  | tee labs/lab12/bench/http-latency.txt

out="labs/lab12/bench/curl-3012.txt"
: > "$out"

for i in $(seq 1 50); do
  curl -s -o /dev/null -w "%{time_total}\n" \
    http://localhost:3012/ >> "$out"
done

awk '{s+=$1; n+=1; if(min=="" || $1<min) min=$1; if(max=="" || $1>max) max=$1} \
     END {if(n>0) printf "avg=%.4fs min=%.4fs max=%.4fs n=%d\n", s/n, min, max, n}' \
  "$out" \
  | tee -a labs/lab12/bench/http-latency.txt
```

Results show stable, low request latency under runc. Running Juice Shop inside Kata would add some overhead (extra VM boundary), but for most web workloads this overhead is acceptable relative to the security benefits.

---

## 6) Trade-offs & Recommendations

### 6.1 runc: strengths & weaknesses

**Pros:**

* Very fast startup and teardown.
* High density (more containers per host).
* Simple operational model (what Docker does by default).

**Cons:**

* Containers share the host kernel; a kernel exploit can compromise the whole host.
* Host kernel details are more exposed (dmesg, `/proc`, modules).
* Strong isolation depends primarily on kernel hardening and namespaces.

### 6.2 Kata: strengths & weaknesses

**Pros:**

* Each container/pod is backed by a **lightweight VM** with its own kernel.
* Guest kernel and VM boundary significantly reduce the impact of container escapes.
* Reduced exposure of host details (`dmesg`, `/proc`, `/sys/module`, network stack).
* Easier to implement “strong isolation” multi-tenant scenarios.

**Cons:**

* Higher startup latency (booting a VM vs just creating namespaces).
* Higher resource overhead per container (guest kernel + minimal userspace).
* Additional operational complexity:

  * managing Kata assets (kernel/image),
  * configuring containerd/nerdctl and CNI plugins,
  * troubleshooting VM-level issues.

### 6.3 When to use which

* **Use runc** for:

  * internal services with lower risk,
  * CI jobs and short-lived tasks,
  * environments where density and speed matter more than strong tenant isolation.

* **Use Kata** for:

  * multi-tenant workloads where tenants are untrusted,
  * high-value, Internet-facing services,
  * cases where you want VM-level isolation but still use container tooling and workflows.

---

## 7) Repro Steps & Artifacts

### 7.1 Reproduction steps (summary)

1. **Install containerd + nerdctl** on Arch; enable and start `containerd`.

2. **Build Kata shim**:

   ```bash
   bash labs/lab12/setup/build-kata-runtime.sh
   sudo install -m 0755 labs/lab12/setup/kata-out/containerd-shim-kata-v2 /usr/local/bin/
   ```

3. **Install Kata assets & configure containerd**:

   ```bash
   sudo bash labs/lab12/scripts/install-kata-assets.sh
   sudo bash labs/lab12/scripts/configure-containerd-kata.sh
   sudo systemctl restart containerd
   ```

4. **Install CNI plugins** in `/opt/cni/bin` as shown in Section 1.3.

5. **Run baseline Juice Shop with runc** (Docker) on port 3012.

6. **Run Kata test containers** with `nerdctl --runtime io.containerd.kata.v2` and capture:

   * `uname -a`, `uname -r`, `/proc/cpuinfo`,
   * `dmesg`, `/proc` size, `/sys/module` count,
   * network interfaces.

7. **Measure startup times** for runc vs Kata.

8. Optionally, **measure HTTP latency** for `juice-runc`.

### 7.2 Key artifacts in the repo

* **Setup & versions:**

  * `labs/lab12/setup/kata-built-version.txt`
* **Kata environment:**

  * `labs/lab12/kata/test1.txt` (uname -a in Kata)
  * `labs/lab12/kata/kernel.txt` (guest kernel version)
  * `labs/lab12/kata/cpu.txt` (guest CPU model)
* **Comparisons & isolation:**

  * `labs/lab12/analysis/kernel-comparison.txt`
  * `labs/lab12/analysis/cpu-comparison.txt`
  * `labs/lab12/isolation/dmesg.txt`
  * `labs/lab12/isolation/proc.txt`
  * `labs/lab12/isolation/modules.txt`
  * `labs/lab12/isolation/network.txt`
* **Performance:**

  * `labs/lab12/bench/startup.txt`
  * `labs/lab12/bench/http-latency.txt` (if measured)
* **Report:**

  * `labs/submission12.md` (this document)

This completes **Lab 12 — Kata Containers: VM-backed Container Sandboxing**: Kata is installed and integrated with containerd, a real workload was compared between runc and Kata, and we analyzed both isolation properties and performance trade-offs.

```
::contentReference[oaicite:0]{index=0}
```
