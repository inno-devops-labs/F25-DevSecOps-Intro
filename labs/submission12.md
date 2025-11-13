# Task 1 — Install and Configure Kata

## Shim

`containerd-shim-kata-v2 --version`:

```bash
Kata Containers containerd shim: id: "io.containerd.kata.v2", version: 3.0.0, commit: e2a8815ba46360acb8bf89a2894b0d437dc8548a
```
## Successful Test Run

`sudo nerdctl run --rm -it --runtime io.containerd.kata.v2 alpine uname -a`:

```bash
Linux 36bf81b37e46 5.15.26 #2 SMP Wed Jul 6 07:12:59 UTC 2022 x86_64 Linux
```

---

# Task 2 — Run and Compare Containers (runc vs kata)

## `juice-runc` health check

```bash
juice-runc: HTTP 200
```

## Kata Containers Running Successfully

`sudo nerdctl run -d --runtime io.containerd.kata.v2 --name kata-test alpine sleep 60`

`sudo nerdctl ps    `:                                                                 

```bash
CONTAINER ID    IMAGE                                      COMMAND                   CREATED          STATUS    PORTS                     NAMES
e30b6cd128b3    docker.io/library/alpine:latest            "sleep 60"                5 seconds ago    Up                                  kata-test
80ee39416d88    docker.io/bkimminich/juice-shop:v19.0.0    "/nodejs/bin/node /j…"    9 minutes ago    Up        0.0.0.0:3012->3000/tcp    juice-runc
```

```sudo nerdctl inspect kata-test | grep -i runtime```:

```bash
"Runtime": "io.containerd.kata.v2",
"CpuRealtimeRuntime": 0,
```

## Kernel Versions Comparision

1. **Host Kernel**:
    - 6.6.87.2-microsoft-standard-WSL2

2. **Kata Guest Kernel**:
    - Linux version 5.15.26 (root@94239f575d46) (gcc (Ubuntu 9.4.0-1ubuntu1~20.04.1) 9.4.0, GNU ld (GNU Binutils for Ubuntu) 2.34) #2 SMP Wed Jul 6 07:12:59 UTC 2022

## CPU Models Comparision

1. Host CPU:
    - **model name**: 12th Gen Intel(R) Core(TM) i5-12450H

2. Kata VM CPU:
    - **model name**: 12th Gen Intel(R) Core(TM) i5-12450H

## Isolation Implications

| Characteristic           | runc                                      | Kata Containers                                  |
|------------------------------|-----------------------------------------------|------------------------------------------------------|
| Isolation type           | Process-based (Linux namespaces & cgroups)    | Hardware-assisted virtualization (KVM / QEMU VM)     |
| Kernel                   | Shared with the host                          | Separate guest kernel                                |
| Security level           | Basic process isolation                       | Strong VM-level isolation                            |
| Performance              | Higher (lightweight, fast startup)            | Slightly lower (VM overhead)                         |
| Resource usage           | Low (shared host kernel and resources)        | Higher (each VM has its own kernel and memory)       |
| Kernel escape risk       | Possible (containers share host kernel)       | Very low (guest kernel is isolated via hypervisor)   |

---

# Task 3 — Isolation Tests

## `dmesg` Output Differences

```bash
Kata VM (separate kernel boot logs):
[    0.000000] Linux version 5.15.26 (root@94239f575d46) (gcc (Ubuntu 9.4.0-1ubuntu1~20.04.1) 9.4.0, GNU ld (GNU Binutils for Ubuntu) 2.34) #2 SMP Wed Jul 6 07:12:59 UTC 2022
[    0.000000] Command line: tsc=reliable no_timer_check rcupdate.rcu_expedited=1 i8042.direct=1 i8042.dumbkbd=1 i8042.nopnp=1 i8042.noaux=1 noreplace-smp reboot=k cryptomgr.notests net.ifnames=0 pci=lastbus=0 console=hvc0 console=hvc1 debug panic=1 nr_cpus=12 scsi_mod.scan=none agent.log=debug
[    0.000000] x86/fpu: Supporting XSAVE feature 0x001: 'x87 floating point registers'
[    0.000000] x86/fpu: Supporting XSAVE feature 0x002: 'SSE registers'
```

## `/proc` filesystem visibility comparison

- **Host**: 160
- **Kata VM**: 52

## Network Interface Configuration in Kata VM

```bash
Kata VM network:
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <NO-CARRIER,BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state DOWN qlen 1000
    link/ether e2:b2:ca:41:5d:dc brd ff:ff:ff:ff:ff:ff
    inet 10.4.0.13/24 brd 10.4.0.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::e0b2:caff:fe41:5ddc/64 scope link tentative 
       valid_lft forever preferred_lft forever
```

## Kernel Module Counts

- **Host kernel modules**: 219
- **Kata guest kernel modules**: 65

## Isolation Boundary Differences

Runtime | Isolation Boundary | Description |
|--------------|------------------------|-----------------|
| runc | Linux kernel (namespaces, cgroups, seccomp) | All containers share the same host kernel, using Linux namespaces and cgroups for process isolation |
| Kata Containers | Virtual Machine boundary (hardware virtualization via KVM/QEMU) | Each container runs inside its own lightweight VM with a separate guest kernel, creating a strong boundary between host and container |

## Security Implications

| Scenario | runc | Kata Containers |
|---------------|-----------|----------------------|
| Container escape | Possible — if a vulnerability in the host kernel or container runtime is exploited, an attacker can escape to the host | Highly unlikely — each container runs in a separate VM, and the hypervisor layer prevents direct access to the host kernel |
| Attack surface | Larger — containers share the same kernel and system calls | Smaller — isolation through hardware virtualization greatly limits host exposure |
| Trade-off | Better performance, weaker isolation | Stronger isolation, slightly higher resource overhead |

---

# Task 4 — Performance Comparison

## Startup Time Comparison

`runc`:
1. `sudo nerdctl run --rm alpine:3.19 echo "test" 2>&1`:  0.01s user 0.01s system 1% cpu 1.221 total
2. `grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv}`:  0.00s user 0.00s system 0% cpu 1.221 total
3. `tee -a labs/lab12/bench/startup.txt`:  0.00s user 0.00s system 0% cpu 1.222 total


`Kata`:
1. `sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.`: 19 echo "test":  0.00s user 0.01s system 0% cpu 2.522 total
2. `grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv}`:  0.00s user 0.00s system 0% cpu 2.522 total
3. `tee -a labs/lab12/bench/startup.txt`:  0.00s user 0.00s system 0% cpu 2.523 total


## HTTP Latency for `juice-runc` Baseline

**Results for `juice-runc`**:
- **avg**: 0.0054s
- **min**: 0.0029s
- **max**: 0.0114s
- **n**: 50

## Performance Tradeoffs Analysis

| Metric | runc | Kata Containers | Notes |
|-------------|-----------|----------------------|------------|
| Startup overhead | Minimal | Higher | VM boot time adds extra startup delay |
| Runtime overhead | Low | Slightly higher | Virtualization layer adds some I/O and memory latency |
| CPU overhead | Negligible | Small | Due to KVM context switches and VM management |

---

## When to Use Each Interpretation

| Use Case | Recommended Runtime | Reason |
|---------------|--------------------------|-------------|
| Fast startup and low latency workloads | runc | Best for microservices, CI pipelines, and short-lived containers |
| Security-sensitive workloads | Kata Containers | Strong isolation (VM boundary) prevents container escape and kernel exploits |
| Untrusted or multi-tenant environments | Kata Containers | Each container runs in a dedicated VM, reducing cross-tenant risk |
| High-performance single-tenant systems | runc | Less overhead, full access to host kernel performance |
